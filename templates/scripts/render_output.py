import sys
import os

def render():
    try:
        template_path = sys.argv[1]
        log_path = sys.argv[2]
        timestamp = sys.argv[3]
        
        if not os.path.exists(template_path):
            print(f"Error: Template {template_path} not found")
            return
            
        with open(template_path, 'r', encoding='utf-8', errors='ignore') as f:
            template = f.read()
            
        log_content = "No log output available."
        if os.path.exists(log_path):
            with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
                log_content = f.read()
                
        output = template.replace('{{COMMAND_OUTPUT}}', log_content)
        output = output.replace('{{TIMESTAMP}}', timestamp)
        
        status = sys.argv[4] if len(sys.argv) > 4 else "COMPLETED"
        output = output.replace('{{STATUS}}', status)
        
        sys.stdout.write(output)
    except Exception as e:
        sys.stderr.write(f"Render Error: {str(e)}\n")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.stderr.write("Usage: render.py template log timestamp\n")
        sys.exit(1)
    render()
