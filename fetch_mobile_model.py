import kagglehub
import shutil
import os

print("Fetching the Llama 3.2 1B MediaPipe (.task) model from Kaggle...")
try:
    # Download latest version of Llama 3.2 1B in TFLite/MediaPipe format
    # Note: Requires accepting the model license on Kaggle and potentially setting KAGGLE_USERNAME / KAGGLE_KEY
    path = kagglehub.model_download("metaresearch/llama-3.2/tflite/1b-instruct-cpu")
    
    # Kaggle downloads it to a cache folder. Let's move it to our workspace.
    dest_path = "./llama3.2_1b_mobile.task"
    
    # Find the .task or .bin file in the downloaded path
    found = False
    for root, dirs, files in os.walk(path):
        for file in files:
            if file.endswith(".task") or file.endswith(".bin"):
                source = os.path.join(root, file)
                shutil.copy2(source, dest_path)
                print(f"✅ Success! Mobile model saved as: {dest_path}")
                print(f"File size: {os.path.getsize(dest_path) / (1024*1024):.2f} MB")
                print("Hand this file over to your Flutter developer!")
                found = True
                exit(0)
    
    if not found:
        print("Downloaded, but couldn't find the .task file in the directory:", path)
    
except Exception as e:
    print("❌ Error fetching the model:", e)
    print("You likely need to log into Kaggle or accept the Llama 3.2 license agreement on the Kaggle website.")
    print("Alternatively, you can manually download the .task file from:")
    print("https://www.kaggle.com/models/metaresearch/llama-3.2/frameworks/tfLite")
