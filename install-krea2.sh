
#!/bin/bash

COMFY=/workspace/ComfyUI
MODELS="$COMFY/models"

mkdir -p "$MODELS"/{diffusion_models,text_encoders,vae,loras}
mkdir -p "$COMFY/custom_nodes"

# ==========================================
# 1. CUSTOM NODES
# ==========================================

cd "$COMFY/custom_nodes" || exit 1

git clone https://github.com/lonecatone23/ComfyUI_LC123_nodes.git 2>/dev/null || true
git clone https://github.com/lonecatone23/ComfyUI_LC_Vision_nodes.git 2>/dev/null || true
git clone https://github.com/lonecatone23/ComfyUI_LC_AV_nodes.git 2>/dev/null || true
git clone https://github.com/lonecatone23/ComfyUI_LC_MaskMaker_nodes.git 2>/dev/null || true
git clone https://github.com/lbouaraba/comfyui-krea2edit.git 2>/dev/null || true

# Install node requirements
for req in "$COMFY"/custom_nodes/*/requirements.txt; do
    [ -f "$req" ] && python -m pip install -r "$req"
done

# ==========================================
# 2. MODEL DOWNLOADER
# ==========================================

download() {
    folder="$1"
    filename="$2"
    url="$3"
    auth="$4"

    target="$MODELS/$folder/$filename"

    if [ -f "$target" ]; then
        echo "EXISTS: $filename"
        return
    fi

    echo "DOWNLOADING: $filename"

    curl -fL -C - \
        --retry 20 \
        --retry-delay 5 \
        --retry-all-errors \
        --connect-timeout 30 \
        --progress-bar \
        -H "Authorization: Bearer $auth" \
        -o "$target.part" \
        "$url"

    if [ $? -eq 0 ]; then
        mv "$target.part" "$target"
        echo "DONE: $filename"
    else
        echo "FAILED: $filename"
    fi
}

# ==========================================
# 3. DIFFUSION MODELS
# ==========================================

download diffusion_models \
  krea2_turbo_fp8_scaled.safetensors \
  "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/diffusion_models/krea2_turbo_fp8_scaled.safetensors" \
  "$HF_TOKEN"

download diffusion_models \
  krea2_turbo_bf16.safetensors \
  "https://civitai.com/api/download/models/3064584?fileId=2943406" \
  "$CIVITAI_TOKEN"

download diffusion_models \
  raw.safetensors \
  "https://huggingface.co/krea/Krea-2-Raw/resolve/main/raw.safetensors" \
  "$HF_TOKEN"

download diffusion_models \
  krealism.safetensors \
  "https://civitai.com/api/download/models/3139976" \
  "$CIVITAI_TOKEN"

download diffusion_models \
  animosity_krea2_turbo.safetensors \
  "https://civitai.com/api/download/models/3130436" \
  "$CIVITAI_TOKEN"

download diffusion_models \
  krea2_turbo.gguf \
  "https://civitai.com/api/download/models/3069586?fileId=2948449" \
  "$CIVITAI_TOKEN"

# ==========================================
# 4. TEXT ENCODERS
# ==========================================

download text_encoders \
  qwen3vl_4b_fp8_scaled.safetensors \
  "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/text_encoders/qwen3vl_4b_fp8_scaled.safetensors" \
  "$HF_TOKEN"

download text_encoders \
  qwen3vl_4b_Heritic.safetensors \
  "https://civitai.com/api/download/models/3066989?fileId=2945735" \
  "$CIVITAI_TOKEN"

# ==========================================
# 5. VAE
# ==========================================

download vae \
  qwen_image_vae.safetensors \
  "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/vae/qwen_image_vae.safetensors" \
  "$HF_TOKEN"

download vae \
  krea2RealVae_v10.safetensors \
  "https://civitai.com/api/download/models/3068442?fileId=2947164" \
  "$CIVITAI_TOKEN"

# ==========================================
# 6. LORA
# ==========================================

download loras \
  krea2_identity_edit_v1_2.safetensors \
  "https://huggingface.co/conradlocke/krea2-identity-edit/resolve/main/krea2_identity_edit_v1_2.safetensors" \
  "$HF_TOKEN"

# ==========================================
# 7. FINISH
# ==========================================

echo "=================================="
echo "MODEL INSTALLATION FINISHED"
echo "=================================="

find "$MODELS" -type f \
  \( -name "*.safetensors" -o -name "*.gguf" \) \
  -printf "%p\n"

echo "Check FAILED messages above."

# Start ComfyUI if the base template does not
# already manage the ComfyUI process.
cd "$COMFY" || exit 1

if ! pgrep -f '[p]ython.*main.py.*--listen' >/dev/null; then
    nohup python main.py \
      --listen 0.0.0.0 \
      --port 8188 \
      > /workspace/comfyui.log 2>&1 &
fi
