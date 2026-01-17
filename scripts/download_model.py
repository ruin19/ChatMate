#!/usr/bin/env python3
"""
下载 Qwen2.5-1.5B 模型的 GGUF 格式文件
"""
from huggingface_hub import hf_hub_download
import os

# 配置
repo_id = "Qwen/Qwen2.5-1.5B-Instruct-GGUF"
filename = "qwen2.5-1.5b-instruct-q4_k_m.gguf"
local_dir = os.path.expanduser("~/Downloads/ChatMate-Models")

print(f"开始下载模型...")
print(f"仓库: {repo_id}")
print(f"文件: {filename}")
print(f"保存位置: {local_dir}")
print("-" * 60)

try:
    # 创建目录
    os.makedirs(local_dir, exist_ok=True)
    
    # 检查文件是否已存在
    target_path = os.path.join(local_dir, filename)
    if os.path.exists(target_path):
        file_size = os.path.getsize(target_path)
        if file_size > 900_000_000:  # 大于900MB认为下载完成
            print(f"\n✅ 模型已存在!")
            print(f"模型路径: {target_path}")
            print(f"文件大小: {file_size / (1024**3):.2f} GB")
            exit(0)
        else:
            print(f"⚠️  发现不完整文件，重新下载...")
            os.remove(target_path)
    
    print("🌐 正在连接 Hugging Face...")
    
    # 下载模型（会自动显示进度条）
    downloaded_path = hf_hub_download(
        repo_id=repo_id,
        filename=filename,
        local_dir=local_dir,
        resume_download=True
    )
    
    print(f"\n✅ 下载成功!")
    print(f"模型路径: {downloaded_path}")
    
    # 显示文件大小
    file_size = os.path.getsize(downloaded_path)
    print(f"文件大小: {file_size / (1024**3):.2f} GB")
    
except KeyboardInterrupt:
    print(f"\n\n⚠️  下载被中断")
    print("可以重新运行脚本继续下载（支持断点续传）")
    exit(130)
except Exception as e:
    print(f"\n❌ 下载失败: {e}")
    import traceback
    traceback.print_exc()
    exit(1)
