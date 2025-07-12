# ddddorc trainer in MacOS with GPU(MPS)

```
git clone https://github.com/sml2h3/dddd_trainer.git
cd dddd_trainer

pip3 install -r requirements.txt
sed -i '' "s/[[:space:]]*device = torch\.device('cuda:{}'/            if hasattr(torch.backends, 'mps') and torch.backends.mps.is_available() and torch.backends.mps.is_built():\n                device = torch.device('mps:{}'.format(str(gpu_id)))\n            else:\n                device = torch.device('cuda:{}'/" nets/__init__.py

pip3 uninstall onnxruntime
pip3 install onnxruntime-silicon
pip3 install torch torchvision torchaudio 



```
