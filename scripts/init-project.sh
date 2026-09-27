#!/usr/bin/env bash
set -e

if [[ -z "$1" ]]; then
  echo "ERROR: No output directory specified."
  echo
  echo "usage: ./init-project.sh <OUTPUT_DIR>"
  echo
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROLE_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="${1%/}/gitlab_issues"
echo "Initializing project to $PROJECT_DIR"
sleep 1

mkdir -p "$PROJECT_DIR"/{roles,collections,vars,templates}

if [[ ! -f "$PROJECT_DIR/ansible.cfg" ]]; then

cat << EOF > "$PROJECT_DIR/ansible.cfg"
[defaults]
inventory = localhost,
roles_path = ./roles
collections_path = ./collections
interpreter_python = auto_silent
host_key_checking = false

EOF
fi

if [[ ! -f "$PROJECT_DIR/manage-gitlab-issues.yml" ]]; then

cat << EOF > "$PROJECT_DIR/manage-gitlab-issues.yml"
---
- name: Manage Gitlab Issues Playbook
  hosts: localhost
  connection: local
  gather_facts: false
  become: false
  roles:
    - gissues

EOF
fi

if [[ ! -f "$PROJECT_DIR/vars/example.yml" ]]; then
  
cat << EOF > "$PROJECT_DIR/vars/example.yml"
# Example of variable usage
# See related documentation for community.general.gitlab_issue ansible module
# Most Parameters for community.general.gitlab_issue are supported and settable based on scope and namespace prefixing
# E.g. api_url = gissues_api_url (Scoped to entire play or variable set)
# Then, title = gissues_issue_list[N].title (Scoped to issue dictionary within a list of dictionaries)

### Example using environment variables to store url and token
# gissues_api_url: "{{ lookup('env', 'GITLAB_URL') }}"
# gissues_api_token: "{{ lookup('env', 'GITLAB_TOKEN') }}"

### Project path is the group/user/parent_project namespace followed by project name, e.g. company/infrastructure, user/lab, devs/application
# gissues_project_path: 'namespace/project'

### Set to true for trusted certificates only
# gissues_validate_certs: false

### List of issues with various keys
### Keys not specified are omitted or defaulted to modules default
# gissues_issue_list:
#   ### Create issue with a jinja template and template variables to use with it. Vars inside template should be formatted as {{ issue.template_vars.<key> }}
#   - title: Hello World
#     state: present
#     state_filter: all
#     template: issue.md.j2
#     template_vars:
#       task_owner: @gino
#       report_to: N/A
#     assignee_ids:
#       - gino
#       - Linus
#       - Elliot
#     labels:
#       - To Do
#       - Linux
#       - Weekly Ops
#     closed: false
#     epic_id: 0
#
#   ### Create issue with regular description text
#   - title: Foo World
#     state: present
#     description: |
#       # Tasks
#       - [x] Task 1
#       - [x] Task 2
#       - [ ] Task 3
#     assignee_ids:
#       - gino
#     labels
#       - Doing
#       - Linux
#     epic_id: 0
#
#   ### Close issue  
#   - title: Bar World
#     state: present
#     closed: true
#     labels:
#       - Done
#       - Linux
#
#   ### Delete issue if closed
#   - title: Goodbye World
#     state: absent
#     state_filter: closed

EOF
fi

if [[ ! -f "$PROJECT_DIR/templates/issue.md.j2" ]]; then

cp "$ROLE_DIR/templates/issue.md.j2" "$PROJECT_DIR/templates/issue.md.j2" 

fi

if [[ ! -e "$PROJECT_DIR/roles/gissues" ]]; then

ln -s "$ROLE_DIR" "$PROJECT_DIR/roles/gissues"

fi

while true; do
  read -rp "Would you like to install dependencies? [y/n]: " answer

  case "$answer" in
    [Yy]) 
      echo "Installing..."
      if [[ ! -d "$PROJECT_DIR/venv" ]]; then
        python3 -m venv "$PROJECT_DIR/venv"
      fi

      source "$PROJECT_DIR/venv/bin/activate"
      pip install -U pip
      pip install -r "$ROLE_DIR/requirements/python.txt"
      ansible-galaxy collection install -p "$PROJECT_DIR/collections" -r "$ROLE_DIR/requirements/ansible.yml" -f
      deactivate
      exit 0
      ;;
    [Nn])
      echo "Skip installing:"
      echo "  - python3 venv"
      echo "  - ansible"
      echo "  - python-gitlab"
      echo "  - community.general"
      echo "Exiting..."
      echo 
      exit 0
      ;;
    *)
      echo "Please enter y or n."
      ;;
  esac
done


