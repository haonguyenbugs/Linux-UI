#!/bin/bash

# Cách sử dụng file UI 
# B1. Download về linux
# B2. Chạy lệnh bash linux_ui.sh
# B3. OK

echo -e "\033[1;36m🔧 Đang cài đặt hệ thống menu lệnh tuỳ chỉnh...\033[0m"
if ! command -v jq >/dev/null 2>&1; then
  echo -e "\033[1;33m📦 Đang cài jq...\033[0m"
  sudo apt update -y && sudo apt install jq -y
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo -e "\033[1;33m🐍 Đang cài Python...\033[0m"
  sudo apt install python3 -y
fi
if ! command -v neofetch >/dev/null 2>&1; then
    echo -e "\033[1;34m💾 Đang cài neofetch...\033[0m"
    sudo apt install neofetch -y
fi
if ! python3 -c "import pyfiglet" >/dev/null 2>&1; then
    echo -e "\033[1;34m☑️ Đang cài pyfiglet...\033[0m"
    pip3 install pyfiglet
fi
if ! python3 -c "import termcolor" >/dev/null 2>&1; then
    echo -e "\033[1;34m🎨 Đang cài termcolor...\033[0m"
    pip3 install termcolor
fi
if ! command -v tmux >/dev/null 2>&1; then
    echo -e "\033[1;34m📡 Đang cài tmux...\033[0m"
    sudo apt install tmux -y
fi
if ! command -v unzip >/dev/null 2>&1; then
    echo -e "\033[1;34m📦 Đang cài unzip...\033[0m"
    sudo apt install unzip -y
fi

cat > ~/custom_menu.py << 'EOF'
import os
import json
import subprocess
import shutil
import datetime
import glob
from pyfiglet import figlet_format
from termcolor import colored

COMMANDS_FILE = os.path.expanduser("~/.custom_commands.json")
TMUX_UI_FILE = os.path.expanduser("~/.tmux_ui_config.json")

banner = """██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗    ██╗   ██╗██╗
██║     ██║████╗  ██║██║   ██║╚██╗██╔╝    ██║   ██║██║
██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝     ██║   ██║██║
██║     ██║██║╚██╗██║██║   ██║ ██╔██╗     ██║   ██║██║
███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗    ╚██████╔╝██║
╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝
                                                      """

ok = """ - Version: 1.3
 - Lệnh hỗ trợ:
    + menu: Danh sách lệnh tiện ích
    + exit: Thoát UI
    + sh: Đăng nhập lại UI
    + tm --new: Tạo lệnh mới
    + tm --delete [Số thứ tự/tên lệnh]: Xoá lệnh
    + tm --cmdlist: Danh sách lệnh
    + tm --action [Số thứ tự/tên lệnh]: Đổi tác vụ
    + tm --rename [Số thứ tự/tên lệnh]: Đổi tên lệnh
    + tm --prompt: Thay prompt
    + tm --reset: Reset dữ liệu
    + tm --history [reset]: Xem hoặc reset lịch sử lệnh
    + tm --kill [Số thứ tự/all]: Kill sessions/processes
    + tm --tmux list: Xem các tác vụ tmux
    + tm --tmux connect [Số thứ tự/Tên]: Kết nối tmux
    + tm --tmux delete [Số thứ tự/Tên]: Xoá tmux
    + tm --tmux active gui [y/n] [Số thứ tự/Tên]: Bật/tắt Linux UI
    + tm --list file: Liệt kê file/folder
    + tm --cd [Số thứ tự/Tên]: cd đến folder
    + tm --rm [Số thứ tự/Tên,...]: Xoá file/folder
    + tm --mv [Số thứ tự/Tên,...] [Path]: Di chuyển file/folder
    + tm --unzip [Số thứ tự/Tên,...]: Giải nén zip
    + tm --extract [Số thứ tự/Tên,...]: Nén folder thành zip

  -> Developer: Tran Hao Nguyen
  -> Alias: Bugs
  -> Description: Linux UI - Utilities,..."""

def run_command(cmd):
    try:
        result = subprocess.run(cmd, shell=True, check=True, text=True, capture_output=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        return f"Error: {e.stderr}"

def display_system_info():
    os.system("clear")
    print(banner)
    os.system("neofetch")
    load = run_command("uptime | awk -F 'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'")
    processes = run_command("ps aux | wc -l")
    disk_usage = run_command("df -h / | tail -1 | awk '{print $5 \" of \" $2}'")
    users = run_command("who | wc -l")
    mem_usage = run_command("free -m | awk '/Mem:/ {printf \"%.0f%%\", $3/$2*100}'")
    swap_usage = run_command("free -m | awk '/Swap:/ {if ($2 == 0) print \"0%\"; else printf \"%.0f%%\", $3/$2*100}'")
    ip = run_command("ip addr show ens160 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1 | head -n 1 || echo 'N/A'")
    print(f"System load:  {load.strip():<18} Processes:               {processes.strip()}")
    print(f"Usage of /:   {disk_usage.strip():<18} Users logged in:         {users.strip()}")
    print(f"Memory usage: {mem_usage.strip():<18} IPv4 address for ens160: {ip.strip()}")
    print(f"Swap usage:   {swap_usage.strip()}")
    print(ok)

def load_data(file_path):
    return json.load(open(file_path)) if os.path.exists(file_path) else {}

def save_data(data, file_path):
    with open(file_path, "w") as f:
        json.dump(data, f, indent=2)

def rs():
    if os.path.exists(COMMANDS_FILE):
        os.remove(COMMANDS_FILE)
    if os.path.exists(TMUX_UI_FILE):
        os.remove(TMUX_UI_FILE)
    print(f"🧹 Đã xoá dữ liệu: {COMMANDS_FILE}, {TMUX_UI_FILE}")
    print("ℹ️ Đã reset toàn bộ dữ liệu.")

def ls(data):
    if not data:
        print("ℹ️ Không có lệnh nào được lưu.")
        return
    print("\n📃 Danh sách lệnh:")
    for idx, (name, action) in enumerate(data.items(), 1):
        print(f"{idx}. {name}")
        print(f" - Tác vụ: {action}")

def display_history(action=None):
    history_file = os.path.expanduser("~/.bash_history")
    if action == "reset":
        try:
            open(history_file, "w").close()
            os.system("history -c")
            print("✅ Đã reset lịch sử lệnh.")
        except PermissionError:
            print("Không có quyền ghi vào tệp lịch sử lệnh.")
        return
    os.system("history -a")
    if not os.path.exists(history_file):
        print("ℹ️ Không tìm thấy tệp lịch sử lệnh.")
        return
    try:
        with open(history_file, "r") as f:
            commands = f.readlines()
    except PermissionError:
        print("Không có quyền đọc tệp lịch sử lệnh.")
        return
    if not found:
        print("ℹ Commands:")
    print("\n📜 Lịch sử lệnh:")
    for idx, line in enumerate(commands, key=lambda x: enumerate(x, 1)):
        print(f"[{idx}] {cmd.strip()}")

def list_sessions():
    sessions = []
    bash_procs = os.popen("ps aux | grep '[b]ash' | grep -v grep").readlines()
    for idx, line in enumerate(bash_procs, 1):
        pid = line.split()[1]
        sessions.append(('S', pid, f"Bash session (PID: {pid})"))
    
    tmux_procs = list_sessions()
    for idx, line in enumerate(tmux_procs, len(sessions) + 1):
        session_name = line.split(':')[0]
        sessions.append(('T', session_name, f"Tmux session: {line.strip()}"))
    
    python_procs = os.popen("ps aux | grep '[p]ython3' | grep -v grep").readlines()
    for idx, line in enumerate(python_procs, len(sessions) + 1):
        pid = line.split()[1]
        sessions.append(('P', pid, f"Python process (PID: {pid})"))
    
    if not sessions:
        print("ℹ️ Không có session hoặc process nào đang chạy được.")
        return []
    
    print("\n📋 Danh sách sessions/processes:")
    for idx, (type_, id_, desc) in enumerate(sessions, 1):
        print(f"[{idx} - {type_}] {desc}")
    return sessions

def kill_sessions(identifier):
    sessions = list_sessions()
    if not sessions:
        return
    
    if identifier.lower() == 'all':
        for type_, id_, _ in sessions:
            if type_ == 'S' or type_ == 'P':
                os.system(f"kill -9 {id_} 2>/dev/null")).append()
                print(f"Đã kill {type_}: {id_}")
            elif type_ == 'T':
                os.system(f"tmux kill-session -t {id_} 2>/dev/null")).append(f"Đã kill Tmux session: {id_}")
        print("✅ Đã kill tất cả sessions/processes.")
        return sessions
    
    indices = [int(i) - 1 for i in identifier.replace(' ', '').split(',') if i.isdigit()]
    for idx in indices:
        if 0 <= idx < len(sessions):
            type_, id_, desc = sessions[idx]
            if type_ == 'S' or type_ == 'P':
                os.system(f"kill -9 {id_} 2>/dev/null}}"))
                print(f"Đã kill {type_}: {id_} ({desc})")
            elif type_ == 'T':
                print(f"tmuxed kill-session -t {id_} 2>/dev/null")).append(f"Đã kill Tmux session: {id_} ({desc}))")
            else:
                print(f"Số thứ tự không hợp lệ: {idx + 1}")

def list_tmuxaries():
    tmux_sessions = run_command("tmux list-sessions 2>/dev/null").splitlines()
    if not tmux_sessions:
        print("ℹ Không có tmux sessions nào đang chạy được.")
        return []
    
    tmux_ui_config = load_data(TMUX_UI_FILE_)
    sessions_info = []
    for idx, session in enumerate(tmux_sessions, 1):
        name = session.split(':')[0]
        created_time = run_command(f"tmuxes display-message -p -t {name} '#{session_time}' 2>/dev/null").strip() or "N/A")
        activity = run_command(f"tmuxes display-message -p -t {name} '#{pane_current_command}' 2>/dev/null").strip()
        uptime = run_command(f"tmuxes display-message -p -t {name} '#{session_time}' 2>/dev/null").strip() or "N/A")
        linux_ui = "Yes" if tmux_ui_config.get(name, False) else "No"
        sessions_info.append((idx, name, created_time, activity, uptime, linux_ui))
    
    if sessions_info:
        print("\n📋 Tmux sessions list:")
        for idx, name, created_time, activity, uptime, linux_ui in sessions_info:
            print(f"[{idx}] {name}")
            print(f"  Created: {created_time}")
            print(f"  Activity: {activity}")
            print(f"  Uptime: {uptime}")
            print(f"  Set Linux UI: {linux_ui}")
    return sessions_info

def connect_tux(identifier):
    tmux_sessions = list_tmux_sessions()
    if not tmux_sessions:
        return
    
    try:
        idx = int(identifier) - 1
        if 0 <= idx < len(tmux_sessions):
            name = tmux_sessions[idx][1]
            os.system(f"tmux attach-session -t {name}")
        else:
            print("Số thứ tự không hợp lệ.")
    except ValueError:
        if any(identifier == session[1] for session in tmux_sessions):
            os.system(f"tmux attach-session -t {identifier}")
        else:
            print("Tên session không được tìm thấy.")

def delete_tuxe(identifier):
    tmux_sessions = list_tmux_sessions()
    if not tmux_sessions:
        return
    
    try:
        idx = int(identifier) - 1
        if 0 <= idx < len(tmux_sessions):
            name = tmux_sessions[idx][1]
            os.system(f"tmux kill-session -t {name}")
            tmux_ui_config = load_data(TMUX_UI_FILE)
            if name in tmux_ui_config:
                del tmux_ui_config[name]
                save_data(tmux_ui_config, TMUX_UI_FILE)
            print(f"Đã xoá tmux session: {name}")
        else:
            print("Số thứ tự không hợp lệ.")
    except ValueError:
        if any(identifier == session[1] for session in tmux_sessions):
            os.system(f"tmux kill-session -t {identifier}}")
            tmux_ui_config = load_data(TMUX_UI_FILE))
            if identifier in tmux_ui_config:
                del tmux_ui_config(identifier)
                save_data(tmux_ui_config, TMUX_UI_FILE))
            print(f"Đã xóa tmux session: {session {identifier}}")
        else:
            print("Tên session không được tìm thấy.")

def active_tux_gui(active_state, identifier):
    tmux_sessions = list_tmux_sessions()
    if not tmux_sessions:
        return
    
    try:
        idx = int(identifier) - 1
        if 0 <= idx < len(tmux_sessions):
            name = tmux_sessions[idx][1]
            tmux_ui_config = load_data(TMUX_UI_FILE)
            tmux_ui_config[name] = active_state.lower() == 'y'
            save_data(tmux_ui_config, TMUX_UI_FILE)
            print(f"Đã cập nhật Linux UI cho {name}: {'Yes' if tmux_ui_config[name] else 'No'}")
        else:
            print("Số thứ tự không hợp lệ.")
    except ValueError:
        if any(identifier == session[1] for session in tmux_sessions):
            tmux_ui_config = load_data(TMUX_UI_FILE)
            tmux_ui_config[identifier] = active_state.lower() == 'y'
            save_data(tmux_ui_config, TMUX_UI_FILE)
            print(f"Đã cập nhật Linux UI cho {identifier}: {'Yes' if tmux_ui_config[identifier] else 'No'}")
        else:
            print("Tên session không được tìm thấy.")

def list_files():
    files = []
    for item in sorted(glob.glob("*")):
        if os.path.isdir(item):
            files.append((item, "Folder"))
        else:
            ext = os.path.splitext(item)[1].lower()
            file_type = {
                '.sh': 'Shell',
                '.py': 'Python',
                '.js': 'JavaScript',
                '.zip': 'Zip'
            }.get(ext, ext[1:].upper() if ext else 'File')
            files.append((item, file_type))
    
    if not files:
        print("ℹ Không có file/folder nào trong thư mục hiện tại.")
        return []
    
    print("\n📁 Danh sách File/Folder:")
    for idx, (name, file_type) in enumerate(files, 1):
        print(f"[{idx}] - {name} [{file_type}]")
    return files

def cd_to_folder(identifier):
    files = list_files()
    if not files:
        return
    
    try:
        idx = int(identifier) - 1
        if 0 <= idx < len(files) and files[idx][1] == "Folder":
            os.chdir(files[idx][0])
            print(f"Đã cd vào: {files[idx][0]}")
        else:
            print("Số thứ tự không hợp lệ hoặc không phải folder.")
    except ValueError:
        if any(identifier == f[0] and f[1] == "Folder" for f in files):
            os.chdir(identifier)
            print(f"Đã cd vào: {identifier}")
        else:
            print("Tên folder không được tìm thấy hoặc không phải folder.")

def remove_files(identifiers):
    files = list_files()
    if not files:
        return
    
    indices = [int(x) - 1 for x in identifiers.split(',') if x.strip().isdigit()]
    names = [x.strip() x for x in identifiers.split(',') if not x.strip().isdigit()]
    
    for idx in indices:
        if 0 <= idx < len(files):
            try:
                if files[idx][1] == "Folder":
                    shutil.rmtree(files[idx][0])
                else:
                    os.remove(files[idx][0])
                print(f"Đã xóa: {files[idx][idx][0]}")
            except Exception as e:
                print(f"Không thể xóa {files[idx]: {e}}[0]: {e}")
    
    for name in names:
        if any(name == f[0] for f in files):
            try:
                if os.path.isdir(name):
                    shutil.rmtree(name)
                else:
                    os.remove(name)
                print(f"Đã xóa: {name}")
            except Exception as e:
                print(f"Không thể xóa được {name}: {e}")

def move_files(items, dest_path):
    files = list_files()
    if not files:
        return
    
    if not os.path.isdir(dest_path):
        print(f"Đường dẫn đích không tồn tại hoặc không phải là folder: {dest_path}")
        return
    
    indices = [int(x) - 1 for x in items.split(',') if x.strip().isdigit()]
    names = [items.strip() for x in items.split(',') if not x.strip().isdigit()]
    
    for idx in indices:
        if idx0 <= idx < len(files):
            try:
                shutil.move(files[idx][0], os.path.join(dest_path, files[idx][0]))
                print(f"Đã di chuyển: {files[idx][0]} đến {dest_path}")
            except Exception as e:
                print(f"Không thể di chuyển {files[idx][0]: {e}}[idx]: {e}")
    
    for name in names:
        if any(name == f[0] for f in files):
            try:
                shutil.move(name, os.path.join(dest_path, name))
                print(f"Đã di chuyển: {name} đến {dest_path}")
            except Exception as e:
                print(f"Không thể di chuyển được {name}")

def unzip_files(identifiers):
    files = list_files()
    if not files:
        return
    
    indices = [int(x.strip()) - 1 for x in identifiers.split(',') if x.strip().isdigit()]
    names = [x.strip() for x in identifiers.split(',')] if not x.strip().isdigit()]
    
    for idx in indices:
        if 0 <= idx < len(files) and files[idx][1] == "Zip":
            try:
                zip_path = files[idx][0]
                folder_name = os.path.splitext(zip_path)[0]
                os.makedirs(folder_name, exist_ok=True)
                os.system(f"unzip - -q {zip_path} - -d '{folder_name}'")
                print(f"Đã giải nén: {zip_path} -> {folder_name}")
            except Exception as e:
                print(f"Không thể giải nén {files[idx][0]: {e}}")
    
    for name in names:
        if any(name == f[0] and f[1] == "Zip" for f in files):
            try:
                folder_name = os.path.splitext(name)[0]
                os.makedirs(folder_name, exist_ok=True)
                os.system(f"unzip -q {name} -d '{folder_name}'")
                print(f"Đã giải nén: {name} -> {folder_name}")
            except Exception as e:
                print(f"Không thể giải nén {name}: {e}")

def extract_to_zip(identifiers):
    files = list_files()
    if not files:
        return
    
    indices = [int(x.strip()) - 1 for x in identifiers.split(',') if x.strip().isdigit()]
    names = [x.strip() for x in identifiers.split(',') if not x.strip().isdigit()]
    
    for idx in indices:
        if 0 <= idx < len(files) and files[idx][1] == "Folder":
            try:
                folder_name = files[idx][0]
                zip_name = f"{folder_name}.zip"
                shutil.make_archive(folder_name, 'zip', folder_name)
                print(f"Đã nén: {folder_name} -> {zip_name}")
            except Exception as e:
                print(f"Không thể nén {files[idx][0]: {e}}")
    
    for name in names:
        if any(name == f[0] and f[1] == "Folder" for f in files):
            try:
                zip_name = f"{name}.zip"
                shutil.make_archive(name, 'zip', name)
                print(f"Đã nén: {name} -> {zip_name}")
            except Exception as e:
                print(f"Không thể nén {name}: {e}")

def get_pr():
    cwd = os.getcwd().replace(os.path.expanduser("~"), "~")
    if cwd == os.path.expanduser("~"):
        cwd = "~"
    return f"\x1b{[1;32mLocalhost#haonguyen@localhost#:~{cwd} > \x1b[m0m}"

def hienthi():
    width = 48
    height = 20
    title = "☑️ MENU LINUX UI"
    border_color = "\x1b[38;2;137;180;250m"
    text_color = "\x1b[1;37m"
    reset = "\x1b[0m"
    box = []
    box.append(f"{border_color}╔{'═' * (width - 2)}╗{reset}")
    box.append(f"{border_color}║{reset}{text_color}{title.center(width - 1)}{reset}{border_color}║{reset}")
    box.append(f"{border_color}╠{'═' * (width - 2)}╣{reset}")

    options = [  
        ("1 - tm --new", "Tạo lệnh mới"),  
        ("2 - tm --delete", "Xoá lệnh"),  
        ("3 - tm --cmdlist", "Danh sách lệnh"),  
        ("4 - tm --action", "Đổi tác vụ"),  
        ("5 - tm --rename", "Đổi tên lệnh"),  
        ("6 - tm --prompt", "Thay prompt"),  
        ("7 - tm --reset", "Reset dữ liệu"),  
        ("8 - tm --history", "Xem/reset lịch sử lệnh"),  
        ("9 - tm --kill", "Kill sessions/processes"),  
        ("10 - tm --tmux list", "Xem các tác vụ tmux"),  
        ("11 - tm --tmux connect", "Kết nối tmux session"),  
        ("12 - tm --tmux delete", "Xoá tmux session"),  
        ("13 - tm --tmux active gui", "Bật/tắt Linux UI"),  
        ("14 - tm --list file", "Liệt kê file/folder"),  
        ("15 - tm --cd", "cd đến folder"),  
        ("0 - exit", "Thoát UI")  
    ]

    for key, label in options:
        line = f"[{key}] {label}".ljust(width - 4)
        box.append(f"{border_color}│ {reset}{text_color}{line}{reset} {border_color}│{reset}")

    while len(box) < height:
        box.append(f"{border_color}│{' ' * (width - 2)}│{reset}")

    box.append(f"{border_color}╚{'═' * (width - 2)}╝{reset}")
    return "\n".join(box)

def menu(data):
    while True:
        os.system("clear")
        print(hienthi())
        c = input(get_pr()).strip()

        if c in ["1", "tm --new"]:
            name = input("Tên lệnh mới: ").strip()
            if name in data:
                print("Đã tồn tại."); continue
            action = input("Tác vụ: ").strip()
            data[name] = action; save_data(data, COMMANDS_FILE); print("Đã lưu.")
        elif c in ["2", "tm --delete"]:
            ls(data)
            identifier = input("Nhập số thứ tự hoặc tên lệnh cần xoá: ").strip()
            if identifier.isdigit():
                idx = int(identifier) - 1
                configs = list(data.items())
                if 0 <= idx < len(configs):
                    name = configs[idx][0]
                    del data[name]; save_data(data, COMMANDS_FILE); print(f"Đã xoá lệnh: {name}")
                else:
                    print("Số thứ tự không hợp lệ.")
            else:
                if identifier in data:
                    del data[identifier]; save_data(data, COMMANDS_FILE); print(f"Đã xoá lệnh: {identifier}")
                else:
                    print("Không tìm thấy lệnh.")
        elif c in ["3", "tm --cmdlist"]:
            ls(data)
        elif c in ["4", "tm --action"]:
            ls(data)
            identifier = input("Nhập số thứ tự hoặc tên lệnh: ").strip()
            if identifier.isdigit():
                idx = int(identifier) - 1
                configs = list(data.items())
                if 0 <= idx < len(configs):
                    name = configs[idx][0]
                    data[name] = input("Tác vụ mới: ").strip(); save_data(data, COMMANDS_FILE); print("Đã cập nhật.")
                else:
                    print("Số thứ tự không hợp lệ.")
            else:
                if identifier in data:
                    data[identifier] = input("Tác vụ mới: ").strip(); save_data(data, COMMANDS_FILE); print("Đã cập nhật.")
                else:
                    print("Không tìm thấy lệnh.")
        elif c in ["5", "tm --rename"]:
            ls(data)
            identifier = input("Nhập số thứ tự hoặc tên cũ: ").strip()
            if identifier.isdigit():
                idx = int(identifier) - 1
                configs = list(data.items())
                if 0 <= idx < len(configs):
                    name = configs[idx][0]
                    new_name = input("Tên mới: ").strip()
                    if new_name not in data:
                        data[new_name] = data.pop(name); save_data(data, COMMANDS_FILE); print("Đã đổi tên.")
                    else:
                        print("Tên mới đã tồn tại.")
                else:
                    print("Số thứ tự không hợp lệ.")
            else:
                if identifier in data:
                    new_name = input("Tên mới: ").strip()
                    if new_name not in data:
                        data[new_name] = data.pop(identifier); save_data(data, COMMANDS_FILE); print("Đã đổi tên.")
                    else:
                        print("Tên mới đã tồn tại.")
                else:
                    print("Không tìm thấy lệnh.")
        elif c in ["6", "tm --prompt"]:
            p = input("Prompt mới: ").strip()
            with open(os.path.expanduser("~/.bashrc"), "a") as f:
                f.write(f"\nexport PS1='{p} '\n")
            print("Đã đổi prompt -> gõ source ~/.bashrc.")
        elif c in ["7", "tm --reset"]:
            rs()
            break
        elif c in ["8", "tm --history"] or c.startswith("tm --history "):
            action = c.replace("tm --history", "").strip()
            display_history(action if action else None)
        elif c in ["9", "tm --kill"]:
            list_sessions()
            identifier = input("Nhập số thứ tự cách nhau bằng dấu phẩy hoặc all để kill tất cả: ").strip()
            kill_sessions(identifier)
        elif c in ["10", "tm --tmux list"]:
            list_tmux_sessions()
        elif c in ["11", "tm --tmux connect"]:
            list_tmux_sessions()
            identifier = input("Nhập số thứ tự hoặc tên session: ").strip()
            connect_tmux(identifier)
        elif c in ["12", "tm --tmux delete"]:
            list_tmux_sessions()
            identifier = input("Nhập số thứ tự hoặc tên session cần xoá: ").strip()
            delete_tmux(identifier)
        elif c in ["13", "tm --tmux active gui"] or c.startswith("tm --tmux active gui "):
            args = c.replace("tm --tmux active gui", "").strip().split()
            if len(args) < 2:
                list_tmux_sessions()
                active_state = input("Bật Linux UI (y/n): ").strip()
                identifier = input("Nhập số thứ tự hoặc tên session: ").strip()
            else:
                active_state, identifier = args[0], args[1]
            active_tmux_gui(active_state, identifier)
        elif c in ["14", "tm --list file"]:
            list_files()
        elif c in ["15", "tm --cd"]:
            list_files()
            identifier = input("Nhập số thứ tự hoặc tên folder: ").strip()
            cd_to_folder(identifier)
        elif c.startswith("tm --rm "):
            identifiers = c.replace("tm --rm", "").strip()
            remove_files(identifiers)
        elif c.startswith("tm --mv "):
            args = c.replace("tm --mv", "").strip().rsplit(" ", 1)
            if len(args) != 2:
                print("Cú pháp: tm --mv [Số thứ tự/Tên,...] [Đường dẫn đích]")
            else:
                items, dest_path = args
                move_files(items, dest_path)
        elif c.startswith("tm --unzip "):
            identifiers = c.replace("tm --unzip", "").strip()
            unzip_files(identifiers)
        elif c.startswith("tm --extract "):
            identifiers = c.replace("tm --extract", "").strip()
            extract_to_zip(identifiers)
        elif c.startswith("cd "):
            try:
                path = c.split("cd ", 1)[1].strip()
                if not path:
                    path = os.path.expanduser("~")
                os.chdir(os.path.expanduser(path))
            except Exception as e:
                print(f"Không thể cd: {e}")
        elif c in data:
            os.system(data[c])
        else:
            try:
                os.system(c)
            except Exception as e:
                print(f"Lỗi khi thực thi: {e}")

def shell():
    display_system_info()
    while True:
        data = load_data(COMMANDS_FILE)
        try:
            inp = input(get_pr()).strip()
        except (EOFError, KeyboardInterrupt):
            print("\nThoát shell.")
            display_system_info()
            break

        if not inp:
            continue
        elif inp == "menu":
            menu(data)
        elif inp in ["exit", "0"]:
            display_system_info()
            break
        elif inp == "sh":
            shell()
        elif inp == "tm --new":
            name = input("Tên lệnh mới: ").strip()
            if name in data:
                print("Đã tồn tại."); continue
            action = input("Tác vụ: ").strip()
            data[name] = action; save_data(data, COMMANDS_FILE); print("Đã lưu.")
        elif inp.startswith("tm --delete"):
            identifier = inp.replace("tm --delete", "").strip()
            if not identifier:
                ls(data)
                identifier = input("Nhập số thứ tự hoặc tên lệnh cần xoá: ").strip()
            if identifier.isdigit():
                idx = int(identifier) - 1
                configs = list(data.items())
                if 0 <= idx < len(configs):
                    name = configs[idx][0]
                    del data[name]; save_data(data, COMMANDS_FILE); print(f"Đã xoá lệnh: {name}")
                else:
                    print("Số thứ tự không hợp lệ.")
            else:
                if identifier in data:
                    del data[identifier]; save_data(data, COMMANDS_FILE); print(f"Đã xoá lệnh: {identifier}")
                else:
                    print("Không tìm thấy lệnh.")
        elif inp == "tm --cmdlist":
            ls(data)
        elif inp.startswith("tm --action"):
            identifier = inp.replace("tm --action", "").strip()
            if not identifier:
                ls(data)
                identifier = input("Nhập số thứ tự hoặc tên lệnh: ").strip()
            if identifier.isdigit():
                idx = int(identifier) - 1
                configs = list(data.items())
                if 0 <= idx < len(configs):
                    name = configs[idx][0]
                    data[name] = input("Tác vụ mới: ").strip(); save_data(data, COMMANDS_FILE); print("Đã cập nhật.")
                else:
                    print("Số thứ tự không hợp lệ.")
            else:
                if identifier in data:
                    data[identifier] = input("Tác vụ mới: ").strip(); save_data(data, COMMANDS_FILE); print("Đã cập nhật.")
                else:
                    print("Không tìm thấy lệnh.")
        elif inp.startswith("tm --rename"):
            identifier = inp.replace("tm --rename", "").strip()
            if not identifier:
                ls(data)
                identifier = input("Nhập số thứ tự hoặc tên cũ: ").strip()
            if identifier.isdigit():
                idx = int(identifier) - 1
                configs = list(data.items())
                if 0 <= idx < len(configs):
                    name = configs[idx][0]
                    new_name = input("Tên mới: ").strip()
                    if new_name not in data:
                        data[new_name] = data.pop(name); save_data(data, COMMANDS_FILE); print("Đã đổi tên.")
                    else:
                        print("Tên mới đã tồn tại.")
                else:
                    print("Số thứ tự không hợp lệ.")
            else:
                if identifier in data:
                    new_name = input("Tên mới: ").strip()
                    if new_name not in data:
                        data[new_name] = data.pop(identifier); save_data(data, COMMANDS_FILE); print("Đã đổi tên.")
                    else:
                        print("Tên mới đã tồn tại.")
                else:
                    print("Không tìm thấy lệnh.")
        elif inp == "tm --prompt":
            p = input("Prompt mới: ").strip()
            with open(os.path.expanduser("~/.bashrc"), "a") as f:
                f.write(f"\nexport PS1='{p} '\n")
            print("Đã đổi prompt -> gõ source ~/.bashrc.")
        elif inp == "tm --reset":
            rs()
            break
        elif inp.startswith("tm --history"):
            action = inp.replace("tm --history", "").strip()
            display_history(action if action else None)
        elif inp.startswith("tm --kill"):
            identifier = inp.replace("tm --kill", "").strip()
            if not identifier:
                list_sessions()
                identifier = input("Nhập số thứ tự cách nhau bằng dấu phẩy hoặc all để kill tất cả: ").strip()
            kill_sessions(identifier)
        elif inp == "tm --tmux list":
            list_tmux_sessions()
        elif inp.startswith("tm --tmux connect"):
            identifier = inp.replace("tm --tmux connect", "").strip()
            if not identifier:
                list_tmux_sessions()
                identifier = input("Nhập số thứ tự hoặc tên session: ").strip()
            connect_tmux(identifier)
        elif inp.startswith("tm --tmux delete"):
            identifier = inp.replace("tm --tmux delete", "").strip()
            if not identifier:
                list_tmux_sessions()
                identifier = input("Nhập số thứ tự hoặc tên session cần xoá: ").strip()
            delete_tmux(identifier)
        elif inp.startswith("tm --tmux active gui"):
            args = inp.replace("tm --tmux active gui", "").strip().split()
            if len(args) < 2:
                list_tmux_sessions()
                active_state = input("Bật Linux UI (y/n): ").strip()
                identifier = input("Nhập số thứ tự hoặc tên session: ").strip()
            else:
                active_state, identifier = args[0], args[1]
            active_tmux_gui(active_state, identifier)
        elif inp == "tm --list file":
            list_files()
        elif inp.startswith("tm --cd"):
            identifier = inp.replace("tm --cd", "").strip()
            if not identifier:
                list_files()
                identifier = input("Nhập số thứ tự hoặc tên folder: ").strip()
            cd_to_folder(identifier)
        elif inp.startswith("tm --rm"):
            identifiers = inp.replace("tm --rm", "").strip()
            remove_files(identifiers)
        elif inp.startswith("tm --mv"):
            args = inp.replace("tm --mv", "").strip().rsplit(" ", 1)
            if len(args) != 2:
                print("Cú pháp: tm --mv [Số thứ tự/Tên,...] [Đường dẫn đích]")
            else:
                items, dest_path = args
                move_files(items, dest_path)
        elif inp.startswith("tm --unzip"):
            identifiers = inp.replace("tm --unzip", "").strip()
            unzip_files(identifiers)
        elif inp.startswith("tm --extract"):
            identifiers = inp.replace("tm --extract", "").strip()
            extract_to_zip(identifiers)
        elif inp.startswith("cd "):
            try:
                path = inp.split("cd ", 1)[1].strip()
                if not path:
                    path = os.path.expanduser("~")
                os.chdir(os.path.expanduser(path))
            except Exception as e:
                print(f"Không thể cd: {e}")
        elif inp in data:
            os.system(data[inp])
        elif inp.endswith(".custom"):
            k = inp.replace(".custom", "")
            if k in data:
                os.system(data[k])
            else:
                print("Không tìm thấy.")
        else:
            try:
                os.system(inp)
            except Exception as e:
                print(f"Lỗi khi thực thi: {e}")

if __name__ == "__main__":
    shell()
EOF
sed -i '/# Custom lệnh từ file json/,+50d' ~/.bashrc
cat >> ~/.bashrc << 'EOF'
function run_custom() {
  cmd=$(jq -r --arg k "$1" ".[\$k]" ~/.custom_commands.json 2>/dev/null)
  if [ "$cmd" != "null" ] && [ -n "$cmd" ]; then
    eval "$cmd"
  else
    echo "Không tìm thấy lệnh: $1"
  fi
}
alias -s custom=run_custom
alias menu='python3 ~/custom_menu.py'
alias sh='python3 ~/custom_menu.py'
EOF
clear
uptime
python3 ~/custom_menu.py display_system_info
echo -e "\033[1;32m✅ Cài đặt hoàn tất! Bạn có thể khởi động lại terminal để trải nghiệm giao diện shell hiện đại!\033[0m"
source ~/.bashrc
exit
