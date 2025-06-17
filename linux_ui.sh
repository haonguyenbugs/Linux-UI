#!/bin/bash

# Cách sử dụng file UI 
# B1. Chạy script trong Linux
# B2. Chạy lệnh 'menu' để vào giao diện hoặc 'sh' để đăng nhập lại UI
# B3. Nhập 'uiexit' để thoát UI
# B4. OK

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

cat > ~/custom_menu.py << 'EOF'
import os
import json
from pyfiglet import figlet_format
from termcolor import colored

COMMANDS_FILE = os.path.expanduser("~/.custom_commands.json")

banner = """████████╗███████╗██████╗ ███╗   ███╗██╗   ██╗██╗  ██╗       ██████╗ ███████╗
╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║   ██║╚██╗██╔╝      ██╔═══██╗██╔════╝
   ██║   █████╗  ██████╔╝██╔████╔██║██║   ██║ ╚███╔╝ █████╗██║   ██║███████╗
   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║   ██║ ██╔██╗ ╚════╝██║   ██║╚════██║
   ██║   ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗      ╚██████╔╝███████║
   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝       ╚═════╝ ╚══════╝
                                                                            """

def load_data(file_path):
    return json.load(open(file_path)) if os.path.exists(file_path) else {}

def save_data(data, file_path):
    with open(file_path, "w") as f:
        json.dump(data, f, indent=2)

def rs():
    if os.path.exists(COMMANDS_FILE):
        os.remove(COMMANDS_FILE)
        print(f"🧹 Đã xoá dữ liệu: {COMMANDS_FILE}")
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
    if not commands:
        print("ℹ️ Lịch sử lệnh trống.")
        return
    print("\n📜 Lịch sử lệnh:")
    for idx, cmd in enumerate(commands, 1):
        print(f"[{idx}] {cmd.strip()}")

def list_sessions():
    sessions = []
    bash_procs = os.popen("ps aux | grep '[b]ash' | grep -v grep").readlines()
    for idx, line in enumerate(bash_procs, 1):
        pid = line.split()[1]
        sessions.append(('S', pid, f"Bash session (PID: {pid})"))
    
    tmux_procs = os.popen("tmux list-sessions 2>/dev/null").readlines()
    for idx, line in enumerate(tmux_procs, len(sessions) + 1):
        session_name = line.split(':')[0]
        sessions.append(('T', session_name, f"Tmux session: {line.strip()}"))
    
    python_procs = os.popen("ps aux | grep '[p]ython3' | grep -v grep").readlines()
    for idx, line in enumerate(python_procs, len(sessions) + 1):
        pid = line.split()[1]
        sessions.append(('P', pid, f"Python process (PID: {pid})"))
    
    if not sessions:
        print("ℹ️ Không có session hoặc process nào đang chạy.")
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
                os.system(f"kill -9 {id_} 2>/dev/null")
                print(f"Đã kill {type_}: {id_}")
            elif type_ == 'T':
                os.system(f"tmux kill-session -t {id_} 2>/dev/null")
                print(f"Đã kill Tmux session: {id_}")
        print("✅ Đã kill tất cả sessions/processes.")
        return
    
    indices = [int(i) - 1 for i in identifier.replace(' ', '').split(',') if i.isdigit()]
    for idx in indices:
        if 0 <= idx < len(sessions):
            type_, id_, desc = sessions[idx]
            if type_ == 'S' or type_ == 'P':
                os.system(f"kill -9 {id_} 2>/dev/null")
                print(f"Đã kill {type_}: {id_} ({desc})")
            elif type_ == 'T':
                os.system(f"tmux kill-session -t {id_} 2>/dev/null")
                print(f"Đã kill Tmux session: {id_} ({desc})")
        else:
            print(f"Số thứ tự không hợp lệ: {idx + 1}")

def get_pr():
    cwd = os.getcwd().replace(os.path.expanduser("~"), "~")
    if cwd == os.path.expanduser("~"):
        cwd = "~"
    return f"\x1b[1;32mLocalhost#haonguyen{cwd} > \x1b[0m"

def hienthi():
    width = 48
    height = 14
    title = "☑️ MENU LINUX UI"
    border_color = "\x1b[38;2;137;180;250m"
    text_color = "\x1b[1;37m"
    reset = "\x1b[0m"
    box = []
    ok = " - Version: 1.2\n - Lệnh hỗ trợ:\n    + menu: Danh sách lệnh tiện ích\n    + uiexit: Thoát UI\n    + sh: Đăng nhập lại UI\n    + tm --new: Tạo lệnh mới\n    + tm --delete [Số thứ tự/tên lệnh]: Xoá lệnh\n    + tm --cmdlist: Danh sách lệnh\n    + tm --action [Số thứ tự/tên lệnh]: Đổi tác vụ\n    + tm --rename [Số thứ tự/tên lệnh]: Đổi tên lệnh\n    + tm --prompt: Thay prompt\n    + tm --reset: Reset dữ liệu\n    + tm --history [reset]: Xem hoặc reset lịch sử lệnh\n    + tm --kill [Số thứ tự/all]: Kill sessions/processes\n\n  -> Developer: Tran Hao Nguyen\n  -> Alias: Bugs\n  -> Description: Linux UI - Utilities,..."
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
        ("0 - uiexit", "Thoát UI")  
    ]

    for key, label in options:
        line = f"[{key}] {label}".ljust(width - 4)
        box.append(f"{border_color}║ {reset}{text_color}{line}{reset} {border_color}║{reset}")

    while len(box) < height:
        box.append(f"{border_color}║{' ' * (width - 2)}║{reset}")

    box.append(f"{border_color}╚{'═' * (width - 2)}╝{reset}")
    return "\n".join(box)

def menu(data):
    while True:
        os.system("clear")
        ok = " - Version: 1.2\n - Lệnh hỗ trợ:\n    + menu: Danh sách lệnh tiện ích\n    + uiexit: Thoát UI\n    + sh: Đăng nhập lại UI\n    + tm --new: Tạo lệnh mới\n    + tm --delete [Số thứ tự/tên lệnh]: Xoá lệnh\n    + tm --cmdlist: Danh sách lệnh\n    + tm --action [Số thứ tự/tên lệnh]: Đổi tác vụ\n    + tm --rename [Số thứ tự/tên lệnh]: Đổi tên lệnh\n    + tm --prompt: Thay prompt\n    + tm --reset: Reset dữ liệu\n    + tm --history [reset]: Xem hoặc reset lịch sử lệnh\n    + tm --kill [Số thứ tự/all]: Kill sessions/processes\n\n  -> Developer: Tran Hao Nguyen\n  -> Alias: Bugs\n  -> Description: Linux UI - Utilities,..."
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
        elif c in ["0", "uiexit"]:
            os.system("bash -c 'source ~/.bashrc; display_system_info'")
            break
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
    os.system("bash -c 'source ~/.bashrc; display_system_info'")
    while True:
        data = load_data(COMMANDS_FILE)
        try:
            inp = input(get_pr()).strip()
        except (EOFError, KeyboardInterrupt):
            print("\nThoát shell."); break

        if not inp:
            continue
        elif inp == "menu":
            menu(data)
        elif inp == "uiexit":
            os.system("bash -c 'source ~/.bashrc; display_system_info'")
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
            if not identifierthorized
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
                os.system.stdout.flush()  # Flush stdout to ensure proper output
                os.system(inp)
            except Exception as e:
                print(f"Lỗi khitemp = inp.replace("tm --action", "").strip()
            if not identifier:
                ls(data)
                identifier = input("Nhập số thứ tự hoặc tên lệnh: ").strip()
            if identifier.isdigit():
                idx = int(identifier) - 1
                configs = list(data.items())
                if 0 <= idx < len(configs):
                    name = configs[idx][0]
                    data[name] = input("Tác vụ mới: ").strip()
                    save_data(data, COMMANDS_FILE)
                    print("Đã cập nhật.")
                else:
                    print("Số thứ tự không hợp lệ.")
            else:
                if identifier in data:
                    data[identifier] = input("Tác vụ mới: ").strip()
                    save_data(data, COMMANDS_FILE)
                    print("Đã cập nhật.")
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
                        data[new_name] = data.pop(name)
                        save_data(data, COMMANDS_FILE)
                        print("Đã đổi tên.")
                    else:
                        print("Tên mới đã tồn tại.")
                else:
                    print("Số thứ tự không hợp lệ.")
            else:
                if identifier in data:
                    new_name = input("Tên mới: ").strip()
                    if new_name not in data:
                        data[new_name] = data.pop(identifier)
                        save_data(data, COMMANDS_FILE)
                        print("Đã đổi tên.")
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

# Add system info display function to .bashrc
sed -i '/# Custom lệnh từ file json/,+20d' ~/.bashrc
cat >> ~/.bashrc << 'EOF'
function run_custom() {
  cmd=$(jq -r --arg k "$1" ".[\$k]" ~/.custom_commands.json 2>/dev/null)
  if [ "$cmd" != "null" ] && [ -n "$cmd" ]; then
    eval "$cmd"
  else
    echo "Không tìm thấy lệnh: $1"
  fi
}

function display_system_info() {
    clear
    echo "$banner"
    neofetch
    load=$(uptime | awk -F 'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    processes=$(ps aux | wc -l)
    disk_usage=$(df -h / | tail -1 | awk '{print $5 " of " $2}')
    users=$(who | wc -l)
    mem_usage=$(free -m | awk '/Mem:/ {printf "%.0f%%", $3/$2*100}')
    swap_usage=$(free -m | awk '/Swap:/ {if ($2 == 0) print "0%"; else printf "%.0f%%", $3/$2*100}')
    ip=$(ip addr show ens160 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1 || echo "N/A")
    echo "System load:  $load                Processes:               $processes"
    echo "Usage of /:   $disk_usage   Users logged in:         $users"
    echo "Memory usage: $mem_usage                 IPv4 address for ens160: $ip"
    echo "Swap usage:   $swap_usage"
    ok=" - Version: 1.2\n - Lệnh hỗ trợ:\n    + menu: Danh sách lệnh tiện ích\n    + uiexit: Thoát UI\n    + sh: Đăng nhập lại UI\n    + tm --new: Tạo lệnh mới\n    + tm --delete [Số thứ tự/tên lệnh]: Xoá lệnh\n    + tm --cmdlist: Danh sách lệnh\n    + tm --action [Số thứ tự/tên lệnh]: Đổi tác vụ\n    + tm --rename [Số thứ tự/tên lệnh]: Đổi tên lệnh\n    + tm --prompt: Thay prompt\n    + tm --reset: Reset dữ liệu\n    + tm --history [reset]: Xem hoặc reset lịch sử lệnh\n    + tm --kill [Số thứ tự/all]: Kill sessions/processes\n\n  -> Developer: Tran Hao Nguyen\n  -> Alias: Bugs\n  -> Description: Linux UI - Utilities,..."
    echo -e "$ok"
}

alias -s custom=run_custom
alias menu='python3 ~/custom_menu.py'
alias sh='python3 ~/custom_menu.py'

# Store the banner in .bashrc for reuse
banner="████████╗███████╗██████╗ ███╗   ███╗██╗   ██╗██╗  ██╗       ██████╗ ███████╗
╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║   ██║╚██╗██╔╝      ██╔═══██╗██╔════╝
   ██║   █████╗  ██████╔╝██╔████╔██║██║   ██║ ╚███╔╝ █████╗██║   ██║███████╗
   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║   ██║ ██╔██╗ ╚════╝██║   ██║╚════██║
   ██║   ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗      ╚██████╔╝███████║
   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝       ╚═════╝ ╚══════╝
                                                                            "

clear
display_system_info
EOF

# Display system info on setup completion
clear
uptime
display_system_info
echo -e "\033[1;32m✅ Cài đặt hoàn tất! Bạn có thể khởi động lại terminal để trải nghiệm giao diện shell hiện đại!\033[0m"
echo -e "Nhập 'menu' hoặc 'sh' để vào UI, 'uiexit' để thoát UI."
exit
