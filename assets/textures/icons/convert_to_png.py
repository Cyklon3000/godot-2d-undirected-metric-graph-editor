import os
import subprocess

def svg_to_png(svg_file):
    """Converts an SVG file to a PNG file using the cairosvg command-line tool.

    Args:
        svg_file: The path to the SVG file.
    """
    png_file = os.path.splitext(svg_file)[0] + ".png"
    try:
        subprocess.run(['cairosvg', svg_file, '-o', png_file], check=True)  # Key change here!
    except subprocess.CalledProcessError as e:
        print(f"Error converting {svg_file}: {e}")
    except FileNotFoundError:
        print("Error: cairosvg command not found. Make sure it's installed and in your PATH.")


if __name__ == "__main__":
    svg_files = [f for f in os.listdir(".") if f.endswith(".svg")]
    for svg_file in svg_files:
        print(f"Converting {svg_file} to PNG...")
        svg_to_png(svg_file)