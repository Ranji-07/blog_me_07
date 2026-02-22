import subprocess
import os

def check_flutter():
    try:
        os.chdir("portfolio")
        print("Running flutter build web to check errors...")
        result = subprocess.run("flutter build web", capture_output=True, text=True, shell=True)
        print("STDOUT:")
        print(result.stdout)
        print("STDERR:")
        print(result.stderr)
    except Exception as e:
        print(f"Error checking flutter: {e}")

if __name__ == "__main__":
    check_flutter()
