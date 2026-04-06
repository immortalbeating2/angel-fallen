"""
========= 游戏聚合资产(全模态)通用自动化管道 =========
game_asset_pipeline.py

【环境隔离安全要求】
绝对不要在代码里硬写入真实的 API Key！请在游戏根目录下，
新建一个纯文本文件，命名为 `.env` (注意有个前导圆点，且无扩展名)。

在您的 `.env` 文件里原样粘贴以下两行并填入真实密钥：
ELEVENLABS_API_KEY=sk-xxxxxx您真实的ElevenLabs密钥xxxxxxxxx
GEMINI_API_KEY=AIzaSyxxxxx您真实的Gemini密钥xxxxxxxxxxxxxx

注意：如果您在使用代码版本控制 (GIT)，请千万记得把 `.env` 写进 `.gitignore` 文件中防泄露！

【使用方式】
  python game_asset_pipeline.py --config ../../data/pipelines/stage7_assets_batch.json
  python game_asset_pipeline.py --config batch.csv
  python game_asset_pipeline.py --status stage7_assets_batch_manifest.json
  python game_asset_pipeline.py --finalize-dir --manifest stage7_assets_batch_manifest.json
  python game_asset_pipeline.py --finalize assets/audio/sfx/click_v2.wav

【配置文件格式】
  支持 JSON 和 CSV 两种格式。详见 data/pipelines/stage7_assets_batch.json 示例。

【完整生命周期】
  1. --config    批量生成资产 → 自动输出产出清单 (manifest)
  2. --status    扫描产出清单，报告哪些资产组待选择/已就绪/已丢失
  3. 人工审阅    打开对应目录，删除不满意的变体
  4. --finalize-dir  批量将所有仅剩1个变体的组正式化

【支持的资产类型 (type 字段)】
  sfx    - 短促拟音特效       (ElevenLabs)     -> .wav
  bgm    - 长篇BGM/环境循环音  (Lyria 3)        -> .ogg
  voice  - 角色台词/旁白配音   (Gemini TTS)     -> .ogg
  image  - 2D 静态图像资产    (Imagen 3/Nano)  -> .png
  video  - 过场动画视频       (Veo)            -> .mp4
==========================================
"""

import os
import sys
import json
import csv
import re
import shutil
import logging
import argparse
from pathlib import Path
from datetime import datetime

# 配置日志格式
logging.basicConfig(level=logging.INFO, format='%(asctime)s - [%(levelname)s] - %(message)s')

# 请确保安装了以下依赖库：
# pip install elevenlabs google-genai python-dotenv tqdm
try:
    from elevenlabs.client import ElevenLabs
    import elevenlabs
except ImportError:
    logging.warning("未检测到 elevenlabs 库。请运行: pip install elevenlabs")

try:
    from google import genai
    from google.genai import types
except ImportError:
    logging.warning("未检测到 google-genai 库。请运行: pip install google-genai")

try:
    from dotenv import load_dotenv, find_dotenv

    # 强制进行沙盒环境变量 (.env) 的安全校验
    _env_path = find_dotenv(usecwd=True)
    if not _env_path:
        logging.error("❌ 致命安全警告: 未在当前游戏根目录树中检测到 `.env` 文件！")
        logging.error("❌ 为防泄露，强烈建议您不要直接改代码里的配置。请立即参看本脚本最顶部的说明，在本地新建 `.env` 隔离文件。")
    else:
        load_dotenv(_env_path)
        logging.info(f"✅ 成功找到并挂载本地沙盒环境隔离库: {_env_path}")

except ImportError:
    logging.warning("未检测到 python-dotenv 库。环境读取隔离可能失效，请运行: pip install python-dotenv")

try:
    from tqdm import tqdm
except ImportError:
    # 如果没装 tqdm，提供一个透明的替代品，不影响功能
    logging.warning("未检测到 tqdm 库，进度条功能将关闭。请运行: pip install tqdm")
    def tqdm(iterable, **kwargs):
        return iterable

# =============================================================
# 支持的资产类型常量
# =============================================================
SUPPORTED_TYPES = {"sfx", "bgm", "voice", "image", "video"}


class GameAssetPipeline:
    """
    全模态通用游戏资产生成管线。
    根据外部 JSON/CSV 配置清单，自动分发不同类型的资产任务到对应的 AI API 执行生成。
    """

    def __init__(self, elevenlabs_api_key: str = None, gemini_api_key: str = None):
        """
        初始化聚合资产生成管道
        """
        # 1. 注册 ElevenLabs (用于生成极高品质的 战斗/UI 音效 SFX)
        self.elevenlabs_key = elevenlabs_api_key or os.environ.get("ELEVENLABS_API_KEY")
        if self.elevenlabs_key:
            self.el_client = ElevenLabs(api_key=self.elevenlabs_key)
            logging.info("ElevenLabs API 客户端初始化成功。")
        else:
            self.el_client = None

        # 2. 注册 Google AI Studio / Gemini (支持 Lyria, Veo, Imagen, TTS)
        self.gemini_key = gemini_api_key or os.environ.get("GEMINI_API_KEY")
        if self.gemini_key:
            self.genai_client = genai.Client(api_key=self.gemini_key)
            logging.info("Google AI Studio (GenAI) 客户端使用快捷 API Key 初始化成功。")
        else:
            self.genai_client = None

        # 3. 注册模型名称常数
        self.lyria_model_name = 'lyria-3'
        self.veo_model_name = 'veo-2.0-generate-001'
        self.imagen_model_name = 'imagen-3.0-generate-001'
        self.nano_banana_model_name = 'nano-banana-2.0-generate-001'

        # 4. Antigravity 环境检测标志
        env_keys = str(os.environ.keys()).lower()
        self.is_antigravity = 'antigravity' in env_keys or os.environ.get("ANTIGRAVITY_MODE") == "1"
        if self.is_antigravity:
            logging.info("💡 检测到 Antigravity 智能体环境。图像类任务将自动让道给 Agent 原生画笔。")

    # =============================================================
    # 配置文件解析器
    # =============================================================

    def load_config(self, config_path: str) -> tuple[dict, list[dict]]:
        """
        从 JSON 或 CSV 文件中解析全局配置和任务清单。
        返回 (global_config, tasks_list)。
        """
        path = Path(config_path)
        if not path.exists():
            logging.error(f"❌ 配置文件不存在: {config_path}")
            return {}, []

        ext = path.suffix.lower()

        if ext == ".json":
            return self._parse_json(path)
        elif ext == ".csv":
            return self._parse_csv(path)
        elif ext == ".md":
            logging.warning("⚠️ Markdown 格式为兼容模式，推荐迁移至 JSON 或 CSV。")
            return self._parse_markdown(path)
        else:
            logging.error(f"❌ 不支持的配置文件格式: {ext}，请使用 .json 或 .csv")
            return {}, []

    def _parse_json(self, path: Path) -> tuple[dict, list[dict]]:
        """解析 JSON 配置文件"""
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        global_config = data.get("global_config", {})
        tasks = data.get("tasks", [])
        logging.info(f"📋 JSON 配置已读取: 全局配置 {len(global_config)} 项, 任务 {len(tasks)} 条")
        return global_config, tasks

    def _parse_csv(self, path: Path) -> tuple[dict, list[dict]]:
        """解析 CSV 配置文件 (列: type, prompt, path, variants, extra)"""
        tasks = []
        with open(path, "r", encoding="utf-8-sig") as f:
            reader = csv.DictReader(f)
            for row in reader:
                task = {
                    "type": row.get("type", "").strip(),
                    "prompt": row.get("prompt", "").strip(),
                    "path": row.get("path", "").strip(),
                    "variants": int(row.get("variants", "1").strip() or "1"),
                }
                # 额外字段（如 voice_name, aspect_ratio 等）
                for key in row:
                    if key not in ("type", "prompt", "path", "variants") and row[key]:
                        task[key] = row[key].strip()
                tasks.append(task)
        logging.info(f"📋 CSV 配置已读取: 任务 {len(tasks)} 条")
        # CSV 没有全局配置头部，返回空字典
        return {}, tasks

    def _parse_markdown(self, path: Path) -> tuple[dict, list[dict]]:
        """从 Markdown 表格中尽力提取任务（降级兼容模式）"""
        import re
        tasks = []
        with open(path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        for line in lines:
            # 尝试匹配 Markdown 表格行: | type | prompt | path | ...
            match = re.match(r'\|\s*(\w+)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|', line)
            if match:
                t, p, pa = match.groups()
                if t.lower() in SUPPORTED_TYPES:
                    tasks.append({"type": t.lower(), "prompt": p.strip(), "path": pa.strip(), "variants": 1})
        logging.info(f"📋 Markdown 兼容解析: 提取到 {len(tasks)} 条任务")
        return {}, tasks

    # =============================================================
    # 提示词三明治拼装引擎
    # =============================================================

    def _build_prompt(self, raw_prompt: str, task_type: str, global_config: dict) -> str:
        """
        将用户的原始提示词通过全局前缀/后缀包裹成标准化的最终提示词，
        以保证跨资产的风格一致性。
        """
        prefix = global_config.get("style_prefix", "")
        suffix = global_config.get("style_suffix", "")

        # 按类型追加类型专属后缀
        type_suffix_key = f"{task_type}_suffix"
        type_suffix = global_config.get(type_suffix_key, "")

        parts = [p for p in [prefix, raw_prompt, type_suffix, suffix] if p]
        return ", ".join(parts)

    # =============================================================
    # 核心生成方法
    # =============================================================

    def generate_sfx(self, prompt: str, output_path: str, duration_seconds: int = 2):
        """[ElevenLabs API] 生成短促音效 (Sound Effects)"""
        if not self.el_client:
            logging.error("ElevenLabs 客户端未初始化，跳过。")
            return False

        logging.info(f"🔊 SFX 生成: {prompt[:40]}... -> {output_path}")
        try:
            result = self.el_client.text_to_sound_effects.convert(
                text=prompt,
                duration_seconds=duration_seconds,
            )
            Path(output_path).parent.mkdir(parents=True, exist_ok=True)
            with open(output_path, "wb") as f:
                for chunk in result:
                    if chunk:
                        f.write(chunk)
            logging.info(f"✅ 音效已保存至: {output_path}")
            return True
        except Exception as e:
            logging.error(f"ElevenLabs 生成失败: {e}")
            return False

    def generate_bgm(self, prompt: str, output_path: str):
        """[Google AI Studio - Lyria 3] 生成 BGM/Ambience"""
        if not self.genai_client:
            logging.error("Gen AI 客户端未初始化。")
            return False

        logging.info(f"🎵 BGM 生成: {prompt[:40]}... -> {output_path}")
        try:
            response = self.genai_client.models.generate_content(
                model=self.lyria_model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="audio/ogg"
                )
            )
            if response.candidates and response.candidates[0].content.parts:
                Path(output_path).parent.mkdir(parents=True, exist_ok=True)
                with open(output_path, "wb") as f:
                    f.write(response.candidates[0].content.parts[0].inline_data.data)
                logging.info(f"✅ BGM 已保存至: {output_path}")
                return True
            else:
                logging.warning("Lyria 未正常返回音频 InlineData。")
                return False
        except Exception as e:
            logging.error(f"Lyria 3 官方调用失败: {e}")
            return False

    def generate_voice(self, prompt: str, output_path: str, voice_name: str = "Aoede"):
        """[Google AI Studio - Gemini Native TTS] 生成配音"""
        if not self.genai_client:
            logging.error("Gen AI 客户端未初始化。")
            return False

        logging.info(f"🗣️ 配音生成: {prompt[:40]}... -> {output_path}")
        try:
            response = self.genai_client.models.generate_content(
                model='gemini-2.5-pro',
                contents=f"Please read this strictly with no other commentary: {prompt}",
                config=types.GenerateContentConfig(
                    response_mime_type="audio/ogg",
                    voice_config=types.VoiceConfig(
                        prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=voice_name)
                    )
                )
            )
            if response.candidates and response.candidates[0].content.parts:
                Path(output_path).parent.mkdir(parents=True, exist_ok=True)
                with open(output_path, "wb") as out:
                    out.write(response.candidates[0].content.parts[0].inline_data.data)
                logging.info(f"✅ 语音档已保存至: {output_path}")
                return True
            else:
                logging.warning("Gemini 未正常返回语音 InlineData。")
                return False
        except Exception as e:
            logging.error(f"Gemini 原生 TTS 合成失败: {e}")
            return False

    def generate_image(self, prompt: str, output_path: str, use_nano_banana: bool = False,
                       aspect_ratio: str = "1:1", seed: int = None):
        """[Google AI Studio - Imagen 3 / Nano Banana] 生成 2D 游戏图像"""
        # 在 Antigravity 环境中自动让道
        if self.is_antigravity:
            logging.info("💡 智能拦截：处于 Antigravity 环境，图像任务已跳过。请在对话框中对 AI 下达指令出图。")
            return False

        if not self.genai_client:
            logging.error("Gen AI 客户端未初始化。")
            return False

        model_name = self.nano_banana_model_name if use_nano_banana else self.imagen_model_name
        label = "Nano Banana (极速)" if use_nano_banana else "Imagen 3 (旗舰)"
        logging.info(f"🎨 图像生成 [{label}]: {prompt[:40]}... -> {output_path}")

        try:
            img_config = types.GenerateImagesConfig(
                number_of_images=1,
                output_mime_type="image/png",
                aspect_ratio=aspect_ratio
            )
            # 如果支持种子锁定，注入 seed
            if seed is not None:
                img_config.seed = seed

            response = self.genai_client.models.generate_images(
                model=model_name,
                prompt=prompt,
                config=img_config
            )

            if response.generated_images:
                Path(output_path).parent.mkdir(parents=True, exist_ok=True)
                with open(output_path, "wb") as f:
                    f.write(response.generated_images[0].image.image_bytes)
                logging.info(f"✅ 视觉资产已保存至: {output_path}")
                return True
            else:
                logging.warning(f"{label} 未能返回图像。")
                return False
        except Exception as e:
            logging.error(f"图像生成 API 调用失败 ({model_name}): {e}")
            return False

    def generate_video(self, prompt: str, output_path: str, image_path: str = None):
        """[Google AI Studio - Veo] 生成过场动画视频"""
        if not self.genai_client:
            logging.error("Gen AI 客户端未初始化。")
            return False

        logging.info(f"🎬 视频生成: {prompt[:40]}... -> {output_path}")
        try:
            contents = []
            if image_path and Path(image_path).exists():
                import PIL.Image
                img = PIL.Image.open(image_path)
                contents.append(img)
            contents.append(
                f"Generate a high quality 60fps game cinematic video: {prompt}"
            )

            response = self.genai_client.models.generate_content(
                model=self.veo_model_name,
                contents=contents,
                config=types.GenerateContentConfig(
                    response_mime_type="video/mp4"
                )
            )
            if response.candidates and response.candidates[0].content.parts:
                Path(output_path).parent.mkdir(parents=True, exist_ok=True)
                with open(output_path, "wb") as f:
                    f.write(response.candidates[0].content.parts[0].inline_data.data)
                logging.info(f"✅ 过场视频已保存至: {output_path}")
                return True
            else:
                logging.warning("Veo 未正常返回视频数据。")
                return False
        except Exception as e:
            logging.error(f"Veo 官方调用失败: {e}")
            return False

    # =============================================================
    # 类型路由分发器
    # =============================================================

    def _dispatch_task(self, task: dict, global_config: dict) -> bool:
        """
        根据任务的 type 字段，将其路由到对应的生成方法。
        返回 True/False 代表成功/失败。
        """
        task_type = task.get("type", "").lower()
        raw_prompt = task.get("prompt", "")
        output_path = task.get("path", "")

        if task_type not in SUPPORTED_TYPES:
            logging.warning(f"⚠️ 未知资产类型 '{task_type}'，跳过任务: {raw_prompt[:30]}...")
            return False

        # 用全局前缀/后缀拼装最终提示词
        final_prompt = self._build_prompt(raw_prompt, task_type, global_config)

        # 从全局配置获取种子 (可被任务级覆盖)
        seed = task.get("seed", global_config.get("seed"))
        if seed is not None:
            seed = int(seed)

        if task_type == "sfx":
            duration = int(task.get("duration", 2))
            return self.generate_sfx(final_prompt, output_path, duration_seconds=duration)

        elif task_type == "bgm":
            return self.generate_bgm(final_prompt, output_path)

        elif task_type == "voice":
            voice_name = task.get("voice_name", "Aoede")
            return self.generate_voice(raw_prompt, output_path, voice_name=voice_name)

        elif task_type == "image":
            use_nano = str(task.get("use_nano_banana", "false")).lower() == "true"
            aspect = task.get("aspect_ratio", "1:1")
            return self.generate_image(final_prompt, output_path, use_nano_banana=use_nano,
                                       aspect_ratio=aspect, seed=seed)

        elif task_type == "video":
            ref_image = task.get("reference_image", None)
            return self.generate_video(final_prompt, output_path, image_path=ref_image)

        return False

    # =============================================================
    # 多变体循环生成引擎
    # =============================================================

    def _generate_with_variants(self, task: dict, global_config: dict) -> dict:
        """
        根据任务的 variants 字段，循环生成多个变体并自动追加 _v1, _v2 后缀。
        返回 {"success": int, "failed": int, "paths": [str]}。
        """
        default_variants = int(global_config.get("default_variants", 1))
        num_variants = int(task.get("variants", default_variants))
        original_path = task.get("path", "")
        result = {"success": 0, "failed": 0, "paths": []}

        for i in range(1, num_variants + 1):
            variant_task = dict(task)
            if num_variants > 1:
                # 注入变体后缀: assets/sfx/click.wav -> assets/sfx/click_v1.wav
                p = Path(original_path)
                variant_path = str(p.parent / f"{p.stem}_v{i}{p.suffix}")
                variant_task["path"] = variant_path
            else:
                variant_task["path"] = original_path

            success = self._dispatch_task(variant_task, global_config)
            if success:
                result["success"] += 1
                result["paths"].append(variant_task["path"])
            else:
                result["failed"] += 1

        return result

    # =============================================================
    # 批量执行入口
    # =============================================================

    def run_batch(self, config_path: str):
        """
        主入口：读取配置清单，批量执行所有生成任务。
        """
        global_config, tasks = self.load_config(config_path)

        if not tasks:
            logging.error("❌ 配置文件中没有发现任何有效任务。")
            return

        logging.info(f"🚀 开始批量执行: 共 {len(tasks)} 条任务")
        total_success = 0
        total_failed = 0
        total_skipped = 0
        manifest_entries = []

        for task in tqdm(tasks, desc="资产生成进度", unit="项"):
            task_type = task.get("type", "").lower()

            # 跳过无效任务
            if not task.get("prompt") or not task.get("path"):
                logging.warning(f"⚠️ 任务缺少 prompt 或 path 字段，跳过。")
                total_skipped += 1
                continue

            result = self._generate_with_variants(task, global_config)
            total_success += result["success"]
            total_failed += result["failed"]

            # 构建 manifest 条目
            original_path = task.get("path", "")
            p = Path(original_path)
            num_variants = int(task.get("variants", int(global_config.get("default_variants", 1))))
            manifest_entries.append({
                "base": p.stem,
                "type": task.get("type", ""),
                "dir": str(p.parent),
                "ext": p.suffix,
                "variants": result["paths"],
                "variants_requested": num_variants,
                "status": "pending" if num_variants > 1 else ("done" if result["success"] > 0 else "failed")
            })

        # 打印最终汇总报告
        logging.info("=" * 50)
        logging.info(f"📊 批量执行完毕!")
        logging.info(f"  ✅ 成功: {total_success}")
        logging.info(f"  ❌ 失败: {total_failed}")
        logging.info(f"  ⏭️ 跳过: {total_skipped}")
        logging.info("=" * 50)

        # 自动输出产出清单 (manifest)
        self._write_manifest(config_path, tasks, global_config, manifest_entries)

    def _write_manifest(self, config_path: str, tasks: list, global_config: dict,
                        manifest_entries: list[dict]):
        """
        在配置文件同目录下输出一份产出清单 JSON，记录所有生成的文件路径和变体信息，
        用于后续 --status 扫描和 --finalize-dir 批量定稿。
        """
        config_p = Path(config_path)
        manifest_name = f"{config_p.stem}_manifest.json"
        manifest_path = config_p.parent / manifest_name

        manifest = {
            "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "config_source": str(config_p.name),
            "entries": manifest_entries
        }

        with open(manifest_path, "w", encoding="utf-8") as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)

        logging.info(f"📋 产出清单已保存: {manifest_path}")
        logging.info(f"   后续可执行: python game_asset_pipeline.py --status {manifest_path}")

    # =============================================================
    # Finalize 子命令：选定变体并正式化
    # =============================================================

    @staticmethod
    def finalize(variant_path: str, drafts_dir: str = None):
        """
        将选定的变体文件复制为无后缀正式版，并将同名其他变体移入 _drafts/ 归档。
        用法: python game_asset_pipeline.py --finalize assets/audio/sfx/click_v2.wav
        """
        import re
        variant = Path(variant_path)
        if not variant.exists():
            logging.error(f"❌ 变体文件不存在: {variant_path}")
            return

        # 用正则提取出不含 _vN 后缀的基础名
        match = re.match(r'^(.+)_v\d+$', variant.stem)
        if not match:
            logging.error(f"❌ 文件名不符合变体格式 (缺少 _vN 后缀): {variant.name}")
            return

        base_name = match.group(1)
        final_path = variant.parent / f"{base_name}{variant.suffix}"

        # 1. 拷贝选定变体为正式版
        shutil.copy2(variant, final_path)
        logging.info(f"✅ 正式版已生成: {final_path}")

        # 2. 将所有同名变体移入 _drafts/ 归档
        drafts = Path(drafts_dir) if drafts_dir else variant.parent / "_drafts"
        drafts.mkdir(parents=True, exist_ok=True)

        for sibling in variant.parent.glob(f"{base_name}_v*{variant.suffix}"):
            dest = drafts / sibling.name
            shutil.move(str(sibling), str(dest))
            logging.info(f"📦 变体已归档: {sibling.name} -> _drafts/")

        logging.info(f"🎉 Finalize 完成! 正式资产: {final_path}")

    # =============================================================
    # 产出清单状态扫描器
    # =============================================================

    @staticmethod
    def status(manifest_path: str):
        """
        扫描产出清单 (manifest)，对比磁盘上实际存在的文件，
        报告哪些资产组已就绪、哪些待选择、哪些已丢失。
        """
        mp = Path(manifest_path)
        if not mp.exists():
            logging.error(f"❌ 产出清单不存在: {manifest_path}")
            return

        with open(mp, "r", encoding="utf-8") as f:
            manifest = json.load(f)

        entries = manifest.get("entries", [])
        ready = []     # 仅剩 1 个变体，可以 finalize
        pending = []   # 仍有多个变体，需要继续筛选
        lost = []      # 0 个变体存活，需要重新生成
        done = []      # 只请求了 1 个变体且成功，无需 finalize

        for entry in entries:
            base = entry.get("base", "")
            directory = entry.get("dir", "")
            ext = entry.get("ext", "")
            requested = entry.get("variants_requested", 1)

            # 如果只请求了 1 个变体（无后缀），直接检查文件是否存在
            if requested <= 1:
                final_file = Path(directory) / f"{base}{ext}"
                if final_file.exists():
                    done.append((base, str(final_file)))
                else:
                    lost.append((base, directory))
                continue

            # 多变体：扫描磁盘上实际存活的 _vN 文件
            surviving = []
            dir_path = Path(directory)
            if dir_path.exists():
                for f in dir_path.glob(f"{base}_v*{ext}"):
                    surviving.append(f.name)

            # 也检查是否已有正式版（之前 finalize 过）
            final_file = dir_path / f"{base}{ext}"
            if final_file.exists():
                done.append((base, str(final_file)))
            elif len(surviving) == 0:
                lost.append((base, directory))
            elif len(surviving) == 1:
                ready.append((base, directory, surviving[0]))
            else:
                pending.append((base, directory, surviving))

        # 输出报告
        logging.info("")
        logging.info("=" * 55)
        logging.info("📊 资产审阅状态报告")
        logging.info("=" * 55)

        logging.info(f"\n  ✅ 已定稿/无需选择: {len(done)} 组")
        for base, path in done:
            logging.info(f"     ✔ {path}")

        logging.info(f"\n  🟢 已就绪 (仅剩1个变体，可执行 --finalize-dir): {len(ready)} 组")
        for base, directory, survivor in ready:
            logging.info(f"     → {directory}/{survivor}")

        logging.info(f"\n  ⚠️ 待选择 (仍有多个变体，请继续删除不满意的): {len(pending)} 组")
        for base, directory, survivors in pending:
            names = ", ".join(survivors)
            logging.info(f"     ⏳ {directory}/{base}  (剩余: {names})")

        logging.info(f"\n  ❌ 全部丢失 (0个变体，建议重新生成): {len(lost)} 组")
        for base, directory in lost:
            logging.info(f"     ✗ {directory}/{base}")

        logging.info("")
        if pending:
            logging.info(f"💡 仍有 {len(pending)} 组资产待确认。请继续删除不满意的变体后重新执行 --status")
        elif ready:
            logging.info(f"💡 有 {len(ready)} 组已就绪！请执行: python game_asset_pipeline.py --finalize-dir --manifest {manifest_path}")
        else:
            logging.info("🎉 所有资产均已定稿，无待处理项！")
        logging.info("=" * 55)

    # =============================================================
    # 批量目录定稿
    # =============================================================

    @staticmethod
    def finalize_dir(manifest_path: str):
        """
        读取产出清单，扫描所有仅剩 1 个变体的组，批量正式化。
        对于仍有多个变体或全部丢失的组，输出提醒。
        """
        mp = Path(manifest_path)
        if not mp.exists():
            logging.error(f"❌ 产出清单不存在: {manifest_path}")
            return

        with open(mp, "r", encoding="utf-8") as f:
            manifest = json.load(f)

        entries = manifest.get("entries", [])
        finalized_count = 0
        pending_count = 0
        lost_count = 0

        for entry in entries:
            base = entry.get("base", "")
            directory = entry.get("dir", "")
            ext = entry.get("ext", "")
            requested = entry.get("variants_requested", 1)

            # 跳过单变体任务（无需 finalize）
            if requested <= 1:
                continue

            dir_path = Path(directory)
            final_file = dir_path / f"{base}{ext}"

            # 已经有正式版则跳过
            if final_file.exists():
                continue

            # 扫描存活变体
            surviving = list(dir_path.glob(f"{base}_v*{ext}")) if dir_path.exists() else []

            if len(surviving) == 0:
                logging.warning(f"❌ 全部丢失，需重新生成: {directory}/{base}")
                lost_count += 1
            elif len(surviving) == 1:
                # 执行 finalize
                GameAssetPipeline.finalize(str(surviving[0]))
                finalized_count += 1
            else:
                names = ", ".join(s.name for s in surviving)
                logging.warning(f"⚠️ 仍有 {len(surviving)} 个变体待筛选: {directory}/{base} ({names})")
                pending_count += 1

        logging.info("")
        logging.info("=" * 50)
        logging.info(f"📊 批量定稿完毕!")
        logging.info(f"  ✅ 已定稿: {finalized_count}")
        logging.info(f"  ⚠️ 待选择: {pending_count}")
        logging.info(f"  ❌ 已丢失: {lost_count}")
        if pending_count > 0:
            logging.info(f"  💡 仍有 {pending_count} 组未处理，请继续删除后重新执行")
        logging.info("=" * 50)


# =============================================================
# 提示词增强辅助工具
# =============================================================

def enhance_prompt_via_gemini(genai_client, raw_idea: str) -> str:
    """
    [辅助工具] 用 Gemini 润色一段粗糙的音效描述为高维提示词。
    """
    if not genai_client:
        return raw_idea

    sys_prompt = (
        "You are an expert game sound designer. Enhance the following short trigger idea into a rich, "
        "vivid sound effect prompt (under 20 words) suitable for an AI sound generator like ElevenLabs. "
        "Game context: dark fantasy, fallen angel, sacred ruins. Just output the prompt text."
    )
    try:
        response = genai_client.models.generate_content(
            model='gemini-2.5-pro',
            contents=f"{sys_prompt}\n\nOriginal Idea: {raw_idea}"
        )
        return response.text.strip()
    except Exception as e:
        logging.error(f"Gemini 扩写提示词失败: {e}")
        return raw_idea


# =============================================================
# CLI 命令行入口
# =============================================================

def main() -> int:
    parser = argparse.ArgumentParser(
        description="游戏聚合资产(全模态)通用自动化管道",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 批量生成
  python game_asset_pipeline.py --config data/pipelines/stage7_assets_batch.json

  # 查看审阅状态
  python game_asset_pipeline.py --status data/pipelines/stage7_assets_batch_manifest.json

  # 批量定稿 (仅剩1个变体的组自动正式化)
  python game_asset_pipeline.py --finalize-dir --manifest data/pipelines/stage7_assets_batch_manifest.json

  # 单个定稿
  python game_asset_pipeline.py --finalize assets/audio/sfx/click_v2.wav
        """
    )
    parser.add_argument("--config", type=str, help="资产配置清单文件路径 (.json / .csv)")
    parser.add_argument("--status", type=str, help="产出清单 (manifest) 路径，扫描审阅进度")
    parser.add_argument("--finalize", type=str, help="选定变体文件路径，执行单个正式化")
    parser.add_argument("--finalize-dir", action="store_true", help="批量定稿模式 (需配合 --manifest)")
    parser.add_argument("--manifest", type=str, help="产出清单路径 (配合 --finalize-dir 使用)")
    parser.add_argument("--elevenlabs-key", type=str, help="ElevenLabs API Key (优先读取 .env)")
    parser.add_argument("--gemini-key", type=str, help="Gemini API Key (优先读取 .env)")

    args = parser.parse_args()

    # 状态扫描
    if args.status:
        GameAssetPipeline.status(args.status)
        return 0

    # 批量目录定稿
    if args.finalize_dir:
        if not args.manifest:
            logging.error("❌ --finalize-dir 需要配合 --manifest 参数指定产出清单路径")
            return 1
        GameAssetPipeline.finalize_dir(args.manifest)
        return 0

    # 单个 finalize
    if args.finalize:
        GameAssetPipeline.finalize(args.finalize)
        return 0

    # 批量生成
    if args.config:
        pipeline = GameAssetPipeline(
            elevenlabs_api_key=args.elevenlabs_key,
            gemini_api_key=args.gemini_key
        )
        pipeline.run_batch(args.config)
        return 0

    # 没有参数时打印帮助
    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
