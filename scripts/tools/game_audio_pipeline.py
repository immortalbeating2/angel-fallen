"""
========= 游戏聚合资产(全模态)自动化管道 =========

【环境隔离安全要求】
绝对不要在代码里硬写入真实的 API Key！请一定要在此脚本同级目录或游戏根目录下，
新建一个纯文本文件，命名为 `.env` (注意有个前导圆点，且无扩展名)。

在您的 `.env` 文件里原样粘贴以下两行并填入真实密钥：
ELEVENLABS_API_KEY=sk-xxxxxx您真实的ElevenLabs密钥xxxxxxxxx
GEMINI_API_KEY=AIzaSyxxxxx您真实的Gemini密钥xxxxxxxxxxxxxx

注意：如果您在使用代码版本控制 (GIT)，请千万记得把 `.env` 写进 `.gitignore` 文件中防泄露！
==========================================
"""

import os
import logging
from pathlib import Path

# 配置日志格式
logging.basicConfig(level=logging.INFO, format='%(asctime)s - [%(levelname)s] - %(message)s')

# 请确保安装了以下依赖库：
# pip install elevenlabs google-genai python-dotenv
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
        logging.error("❌ 致命安全警告: 未在当前或项目上级目录检测到 `.env` 文件！")
        logging.error("❌ 为防泄露，强烈建议您不要直接改代码里的配置。请立即参看本脚本最顶部的说明，在本地新建 `.env` 隔离文件。")
    else:
        load_dotenv(_env_path)
        logging.info(f"✅ 成功找到并挂载本地沙盒环境隔离库: {_env_path}")
        
except ImportError:
    logging.warning("未检测到 python-dotenv 库。环境读取隔离可能失效，请运行: pip install python-dotenv")

class GameAudioPipeline:
    def __init__(self, elevenlabs_api_key: str = None, gemini_api_key: str = None):
        """
        初始化聚合音频生成管道
        """
        # 1. 注册 ElevenLabs (用于生成极高品质的 战斗/UI 音效 SFX)
        self.elevenlabs_key = elevenlabs_api_key or os.environ.get("ELEVENLABS_API_KEY")
        if self.elevenlabs_key:
            self.el_client = ElevenLabs(api_key=self.elevenlabs_key)
            logging.info("ElevenLabs API 客户端初始化成功。")
        else:
            self.el_client = None

        # 2. 注册 Google AI Studio / Gemini (支持 Lyria, Veo, 面向未来的原生 TTS)
        self.gemini_key = gemini_api_key or os.environ.get("GEMINI_API_KEY")
        if self.gemini_key:
            # 最新文档的 google-genai SDK 仅仅需要一个 'AIza...' 开头的 API Key 字符串！无需 JSON。
            self.genai_client = genai.Client(api_key=self.gemini_key)
            logging.info("Google AI Studio (GenAI) 客户端使用快捷 API Key 初始化成功。")
        else:
            self.genai_client = None

        # 3. 注册 Lyria 3 与 Veo 模型名称常数
        self.lyria_model_name = 'lyria-3'
        self.veo_model_name = 'veo-2.0-generate-001' # 目前最新版的 Veo API 模型节点
        
        # 4. 注册 视觉资产生成 模型节点
        # 【注】Nano Banana 是目前极速生图的黑科技；Imagen 3 是高质量主画笔。
        self.imagen_model_name = 'imagen-3.0-generate-001'
        self.nano_banana_model_name = 'nano-banana-2.0-generate-001' # 根据实验性后台实际名称变动而变动


    def generate_sfx(self, prompt: str, output_path: str, duration_seconds: int = 2):
        """
        [ElevenLabs API]
        根据文本提示词生成短促音效 (Sound Effects)
        非常适合：UI短音效，技能打击，碎片掉落等。
        """
        if not self.el_client:
            logging.error("ElevenLabs 客户端未初始化，跳过生成。")
            return

        logging.info(f"正在生成音效 (SFX): {prompt} -> {output_path}")
        try:
            # 调用最新的 ElevenLabs Sound Effects 功能
            result = self.el_client.text_to_sound_effects.convert(
                text=prompt,
                duration_seconds=duration_seconds,
            )
            
            # 由于返回的是生成器，我们需要将其写出为音频文件
            Path(output_path).parent.mkdir(parents=True, exist_ok=True)
            with open(output_path, "wb") as f:
                for chunk in result:
                    if chunk:
                        f.write(chunk)
            logging.info(f"✅ 音效已保存至: {output_path}")
        except Exception as e:
            logging.error(f"ElevenLabs 生成失败: {e}")

    def generate_voiceover_gemini(self, text: str, output_path: str, voice_name: str = "Aoede"):
        """
        [Google AI Studio - Gemini Native TTS]
        直接用最新的 Gemini API 字符串 Key 调取文字转语音，脱离繁重 GCP JSON 凭据。
        """
        if not self.genai_client:
            logging.error("Gen AI 客户端未初始化，无法生成配音。")
            return

        logging.info(f"正在通过 Gemini 原生文字转语音接口合成: {text[:20]}... -> {output_path}")
        try:
            # 调用最新的语音多模态输出 (配置声音如 Aoede, Puck 等)
            response = self.genai_client.models.generate_content(
                model='gemini-2.5-pro',
                contents=f"Please read this strictly with no other commentary: {text}",
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
            else:
                logging.warning("Gemini 未正常返回语音 InlineData。")
        except Exception as e:
            logging.error(f"Gemini 原生 TTS 合成失败: {e}")

    def enhance_audio_prompt_via_gemini(self, raw_idea: str) -> str:
        """
        [Google AI Studio / Gemini API]
        辅助工具：当遇到生硬的音效词汇时，用 Gemini 根据游戏世界观润色成 ElevenLabs 容易理解的高维提示词。
        """
        if not self.genai_client:
            logging.warning("Gen AI 客户端未初始化，返回原始字符串。")
            return raw_idea

        sys_prompt = (
            "You are an expert game sound designer. Enhance the following short trigger idea into a rich, "
            "vivid sound effect prompt (under 20 words) suitable for an AI sound generator like ElevenLabs. "
            "Game context: dark fantasy, fallen angel, sacred ruins. Just output the prompt text."
        )
        try:
            response = self.genai_client.models.generate_content(
                model='gemini-2.5-pro',
                contents=f"{sys_prompt}\n\nOriginal Idea: {raw_idea}"
            )
            return response.text.strip()
        except Exception as e:
            logging.error(f"Gemini 扩写提示词失败: {e}")
            return raw_idea

    def generate_bgm_and_ambience(self, prompt: str, output_path: str):
        """
        [Google AI Studio - Lyria 3 原生接口]
        利用最新开放的 Lyria 3 API 官方节点生成极高品质 BGM 编曲。
        """
        if not self.genai_client:
            logging.error("Gen AI 客户端未初始化。")
            return
            
        logging.info(f"正在调用原生 Lyria 3 生成 BGM: {prompt[:20]}... -> {output_path}")
        try:
            # 按照最高级别文档规范调用 google-genai SDK 进行生成
            response = self.genai_client.models.generate_content(
                model=self.lyria_model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="audio/ogg"
                )
            )
            # 解析最新的 response 结构获取 base64/字节流
            if response.candidates and response.candidates[0].content.parts:
                Path(output_path).parent.mkdir(parents=True, exist_ok=True)
                with open(output_path, "wb") as f:
                    f.write(response.candidates[0].content.parts[0].inline_data.data)
                logging.info(f"✅ BGM 已保存至: {output_path}")
            else:
                logging.warning("Lyria 未正常返回音频 InlineData。")
        except Exception as e:
            logging.error(f"Lyria 3 官方调用失败: {e}")

    def generate_cinematic_veo(self, image_path: str, prompt: str, output_path: str):
        """
        [Google AI Studio - Veo 原生接口]
        利用最新开放的 Veo 视频模型，基于静帧（我们之前生成的结局CG静帧）和提示词生成游戏过场动画。
        """
        if not self.genai_client:
            logging.error("Gen AI 客户端未初始化。")
            return
            
        logging.info(f"正在调用原生 Veo 将静帧图转化为视频: {output_path}")
        try:
            import PIL.Image
            img = PIL.Image.open(image_path)
            
            # 使用官方 SDK 并入图像和文本混合输入
            response = self.genai_client.models.generate_content(
                model=self.veo_model_name,
                contents=[img, f"Generate a high quality 60fps game cinematic video based on this keyframe and prompt: {prompt}"],
                config=types.GenerateContentConfig(
                    response_mime_type="video/mp4"
                )
            )
            if response.candidates and response.candidates[0].content.parts:
                Path(output_path).parent.mkdir(parents=True, exist_ok=True)
                with open(output_path, "wb") as f:
                    f.write(response.candidates[0].content.parts[0].inline_data.data)
                logging.info(f"✅ 过场视频 CG 已保存至: {output_path}")
        except Exception as e:
            logging.error(f"Veo 官方跑视频调用失败: {e}")

    def generate_image_asset(self, prompt: str, output_path: str, use_nano_banana: bool = False, aspect_ratio: str = "1:1"):
        """
        [Google AI Studio - Imagen 3 / Nano Banana 原生接口]
        在外部脱离 Antigravity 时，全自动通过 API 批量生成高质量像素的 2D 游戏图像资产。
        """
        # 【内置防呆】智能判断：如果脚本发现是由 Antigravity Agent 执行的，则自动跳过，鼓励使用 Agent 原生内置的高级画图工具
        env_keys = str(os.environ.keys()).lower()
        if 'antigravity' in env_keys or os.environ.get("ANTIGRAVITY_MODE") == "1":
            logging.info("💡 智能拦截：检测到当前正处于 Antigravity 智能体环境！已拦截底层 API 生图，为了获取最高质量图形，建议直接在对话框里对 AI 下达指令出图！")
            return

        if not self.genai_client:
            logging.error("Gen AI 客户端未初始化。")
            return
            
        model_name = self.nano_banana_model_name if use_nano_banana else self.imagen_model_name
        model_label = "【闪电级】Nano Banana (极速量产道具图标)" if use_nano_banana else "【旗舰级】Imagen 3 (高精度关卡地块/角色原画)"
        logging.info(f"正在调用 {model_label} 生成视觉资产: {output_path}")
        
        try:
            # 使用最新的 google-genai 专属生图端点 generate_images
            response = self.genai_client.models.generate_images(
                model=model_name,
                prompt=prompt,
                config=types.GenerateImagesConfig(
                    number_of_images=1,
                    output_mime_type="image/png",
                    aspect_ratio=aspect_ratio
                )
            )
            
            if response.generated_images:
                Path(output_path).parent.mkdir(parents=True, exist_ok=True)
                with open(output_path, "wb") as f:
                    f.write(response.generated_images[0].image.image_bytes)
                logging.info(f"✅ 视觉资产已保存至: {output_path}")
            else:
                logging.warning(f"由于内容安全策略截断或服务器异常，{model_label} 未能返回图像。")
        except Exception as e:
            logging.error(f"图像生成官方 API 调用抛出异常 ({model_name}): {e}")

if __name__ == "__main__":
    # ==========================
    # 填入您配置好的 API Keys (也可以通过直接创建 .env 读取)
    # ==========================
    ELEVENLABS_KEY = "sk-xxxxxxxxxxxxxx" # 替换为您申请好的真实 ElevenLabs API Key
    GEMINI_KEY = "AIzaSxxxxxxxxxxx"      # Google AI Studio 分发的纯字符串 Key (极其轻量)

    pipeline = GameAudioPipeline(
        elevenlabs_api_key=ELEVENLABS_KEY,
        gemini_api_key=GEMINI_KEY
    )
    
    # [演示 1.1: SFX 短促音效] - 调用 ElevenLabs
    # logging.info("========= 开始批量自动生成 Stage 7 提示词母版音效 =========")
    # sfx_tasks = [
    #     ("short game ui stinger, holy relic activation, dark fantasy, bright metallic shimmer with ancient rune pulse, under 1 second", 
    #      "d:/Desktop/Project/Game/angel-fallen/assets/audio/sfx/sfx_ui_relic_activate.wav"),
    #     ("reward claim stinger, sacred archive unlock, dark fantasy, elegant metallic resonance, subtle choir sparkle, under 1.5 seconds", 
    #      "d:/Desktop/Project/Game/angel-fallen/assets/audio/sfx/sfx_reward_archive_unlock.wav"),
    #     ("hidden layer unlock sound, forbidden archive seal opening, dark fantasy, restrained impact, low ritual resonance, under 2 seconds", 
    #      "d:/Desktop/Project/Game/angel-fallen/assets/audio/sfx/sfx_hidden_seal_break.wav"),
    # ]
    # for prompt, target_path in sfx_tasks:
    #     pipeline.generate_sfx(prompt=prompt, output_path=target_path, duration_seconds=2)

    # [演示 1.2: BGM 长环境音] - 调用官方最新原生接口 Lyria 3 产出 BGM
    # pipeline.generate_bgm_and_ambience(
    #     prompt="dark fantasy menu theme, fallen angel tragedy, solemn choir textures, distant bells...",
    #     output_path="d:/Desktop/Project/Game/angel-fallen/assets/audio/bgm/bgm_main_menu_fallen_sanctuary.ogg"
    # )

    # [演示 1.3: Image 纯视觉资产生成] - 调用 Imagen 3 / Nano Banana
    # pipeline.generate_image_asset(
    #     prompt="dark fantasy icon, glowing holy health potion, detailed pixel art style, high contrast, dark background",
    #     output_path="d:/Desktop/Project/Game/angel-fallen/assets/sprites/items/potion_health.png",
    #     use_nano_banana=True, # 需要快速跑几百个小药水、碎片的占位符就设为 True 调 Nano Banana
    #     aspect_ratio="1:1"
    # )

    # [演示: 调用官方最新原生接口 Veo 将结局静帧转化为 MP4 过场动画]
    # pipeline.generate_cinematic_veo(
    #     image_path="d:/Desktop/Project/Game/angel-fallen/assets/sprites/concepts/concept_cinematic_ending_v1.png",
    #     prompt="Camera slowly pans up revealing the massive divine gate, god rays shimmering through the dust, epic lighting",
    #     output_path="d:/Desktop/Project/Game/angel-fallen/assets/video/ending_cutscene.mp4"
    # )
