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
display_skipped_hosts = false
interpreter_python = ./venv/bin/python3

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
# See related documentation for community.general.gitlab_issue ansible module


# gissues_api_url: "{{ lookup('env', 'GITLAB_URL') }}"
# gissues_api_token: "{{ lookup('env', 'GITLAB_PRIVATE_TOKEN') }}"

# gissues_project_path: 'namespace/project'

# gissues_validate_certs: true
# gissues_ca_path: ''

# gissues_issue_list:
#   - title: ''
#     state: present
#     state_filter: all
#     closed: false
#     description: ''
#     description_path: ''
#     template: issue.md.j2
#     template_vars:
#       task_owner: ''
#       report_to: ''
#       task_brief: ''
#       delivery_specifics: ''
#       reporting_details: ''
#       background_details: ''
#     assignee_ids: []
#     labels: []
#     epic_id: 0
#     milestone_search: ''
#     milestone_search_id: ''
#
# Note: issue title is the only mandatory key in `gissues_issue_list`
#
# Note: description precedence = templates > description_path > description
#
# Note: `gissues_issue_list.template_vars.*` define keys to be used in selected template in the form of '{{ issue.template_vars.your_key }}'
#
# Note: milestone_search and milestone_search_id are required together
#
# Note: assignee_ids take usernames minus '@' symbol
#
# Note: If any field reports changed, all fields are resubmitted regardless if previously set fields are still defined.

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
      sleep 1
      if [[ ! -d "$PROJECT_DIR/venv" ]]; then
        python3 -m venv "$PROJECT_DIR/venv"
      fi

      source "$PROJECT_DIR/venv/bin/activate"
      pip install -U pip
      pip install -r "$ROLE_DIR/requirements/python.txt"
      #ansible-galaxy collection install -p "$PROJECT_DIR/collections" -r "$ROLE_DIR/requirements/ansible.yml" -f
      deactivate

      COMMUNITY_GENERAL_DIR="$PROJECT_DIR/collections/ansible_collections/community/general"

      if [[ ! -d "$COMMUNITY_GENERAL_DIR" ]]; then
        mkdir -p "$COMMUNITY_GENERAL_DIR"
        git clone https://github.com/gino-labs/community.general.git "$COMMUNITY_GENERAL_DIR"
      fi

      break
      ;;
    [Nn])
      echo "Skipping install..."
      echo "Dependencies:"
      echo "  - ansible"
      echo "  - python-gitlab"
      echo "  - community.general"
      break
      ;;
    *)
      echo "Please enter y or n."
      ;;
  esac
done

if [[ ! -f ~/.python-gitlab.cfg ]]; then

echo
echo "Setting up ~/.python-gitlab.cfg"
cat << EOF > ~/.python-gitlab.cfg
[global]
default = gitlab_instance
ssl_verify = true
timeout = 5

[gitlab_instance]
url = https://gitlab.example.com
private_token = ''
api_version = 4

EOF
fi

if [[ ! -d "$PROJECT_DIR/tests" ]]; then
  echo
  echo "Copying tests..."
  cp -a "$ROLE_DIR/tests" "$PROJECT_DIR/tests"
fi

echo
echo "Done! See project at $PROJECT_DIR"
sleep 1
