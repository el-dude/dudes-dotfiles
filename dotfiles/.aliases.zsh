#!/bin/zsh
# .aliases.zsh

# ----------------------------------------
# Commands
# ----------------------------------------

alias k='kubectl'
alias jp='jupyter notebook'
alias mkdir="mkdir -p"
alias reload="source ~/.zshrc"
alias vsco="code ."
alias v="source ./venv/bin/activate"
alias gpm="git push origin master"
alias dcr='docker-compose run'
alias dcrm='docker-compose run --rm'
alias genpw='dd if=/dev/urandom bs=64 count=1 2>/dev/null | base64'
alias awsconn='_connect_aws_ssm'

# Polo
alias polopy="source ~/virtualenv/polopy3.9/bin/activate"
alias awsecsprod="aws ssm start-session --target \$(aws ecs describe-container-instances --cluster PROD-ECS-CLUSTER --container-instances \$(aws ecs list-container-instances --cluster PROD-ECS-CLUSTER | jq -r '.containerInstanceArns[0]') | jq -r '.containerInstances[0].ec2InstanceId')"
alias awstest="aws ssm start-session --region ap-northeast-1 --target \$(aws ecs describe-container-instances --cluster TEST-ECS-CLUSTER --region ap-northeast-1 --container-instances \$(aws ecs list-container-instances --region ap-northeast-1 --cluster TEST-ECS-CLUSTER | jq -r '.containerInstanceArns[0]') | jq -r '.containerInstances[0].ec2InstanceId')"

# ----------------------------------------
# Libraries
# ----------------------------------------

source $HOME/.aws.zsh
source $HOME/.helpers.zsh
source $HOME/.1password.zsh
source $HOME/.jetbrains.zsh
source $HOME/.gcloud.zsh

# ----------------------------------------
# Utilities
# ----------------------------------------

# OP 1Password functions
# OP login
OP_POLO_ACCOUNT="REPALCE THIS WITH ACCOUNT"
OP_POLO_USER="REPALCE THIS WITH USER"
OP_SECRET_KEY="REPALCE THIS WITH KEY"
opon() {
  if [[ -z $OP_SESSION_polo ]]; then
    export OP_SESSION_polo=$(op signin --output=raw ${OP_POLO_ACCOUNT} ${OP_POLO_USER} ${OP_SECRET_KEY})
  else
    echo "${OP_SESSION_polo} is already set try running signing out and signing in again"
  fi
}

opoff () {
  eval $(op signout)
  unset OP_SESSION_polo
}

### ssm sessions
_connect_aws_ssm() {
  AWS_INSTANCE_ID="${1}"
  shift
  AWS_REGION="${1}"
  [[ ! -z ${AWS_INSTANCE_ID} ]] || echo "$(date) ERROR: No Instance ID was provided";
  # lets set the default to eu-west if not specified.
  [[ ! -z ${AWS_REGION} ]] || AWS_REGION="eu";
  # set the region
  if [[ ${AWS_REGION} =~ "us" ]]; then
    R="us-east-1"
  elif [[ ${AWS_REGION} =~ "eu" ]]; then
    R="eu-west-1"
  elif [[ ${AWS_REGION} =~ "ap" ]]; then
    R="ap-northeast-1"
  else
    echo "$(date) ERROR: this alias only excepts us & eu as args for the region"
  fi
  if [[ ! -z ${AWS_INSTANCE_ID} && ${R} ]]; then
    echo ${R}
    polopy
    aws-auth CFN-Poloniex-SSO-Ops # make sure we have a session to use.
    aws ssm start-session --target ${AWS_INSTANCE_ID} --region ${R}
  else
    echo "$(date) ERROR: neither of the vars were set."
  fi
}

# Create a GitHub PR
#
# Make sure to be in a local branch
# make sure to push the branch to git beforehand
#
GITURL="https://github.com"
pr() {
  #local repo=$(git remote -v | grep -m 1 "upstream" | sed -e "s/.*github.com[:/]\(.*\)\.git.*/\1/")
  local repo=$(git remote -v | grep -m 1 "origin" | sed -e "s/.*github.com[:/]\(.*\)\.git.*/\1/")
  local branch=$(git name-rev --name-only HEAD)
  echo "... creating pull request for branch \"${branch}\" in \"${repo}\""
  open "${GITURL}/${repo}/compare/${branch}?expand=1"
}

# update the fork with the upstream repo.
git-update-fork () {
  git checkout master
  git fetch upstream
  git merge upstream/master
  git push
}

# Setup your local git fork with the upstream repo
git-setup() {
    DUDES_REPO=$1
    # Ensure it's my GitHub Repo (Not Poloniex)
    if [[ $DUDES_REPO != "git@github.com:el-dude/"* ]]; then
        echo "ERROR: Expecting GitHub repository in format git@github.com:el-dude/repository.git."
        return
    fi

    POLO_REPO=$(echo $DUDES_REPO | sed 's|el-dude|poloniex|g')
    REPO_BASE_NAME=$(echo $DUDES_REPO | sed 's|git@github.com:el-dude/||g' | sed 's|.git||g')
    REPO_CHECKOUT="${HOME}/Git/${REPO_BASE_NAME}-el-dude"

    git clone "$DUDES_REPO" "$REPO_CHECKOUT"
    cd "$REPO_CHECKOUT"
    git remote add upstream "$POLO_REPO"

    echo "el-dude repo:      $DUDES_REPO"
    echo "polo repo:  $POLO_REPO"
    echo "repo base name: $REPO_BASE_NAME"
    echo "repo checkout:  $REPO_CHECKOUT"
}

# fix git signing with GPG keys
MYSIGKEY="PUT YOUR GPG SIGNING KEY HERE"
git-fix-email-signing () {
  GIT_SIGNING_KEY="${MYSIGKEY}"
  GIT_EMAIL="PUT YOUR GITHUB EMAIL ASSOCIATED WITH KEY HERE"
  echo "Original Global Author Email: '$(git config --global user.email)'"
  echo "Original Local Author Email: '$(git config user.email)'"
  echo "Setting git author email to '$GIT_EMAIL'."
  git config --global user.email "$GIT_EMAIL"
  git config user.email "$GIT_EMAIL"
  echo "Done."
  echo "Original Global Signing Key: '$(git config --global user.signingkey)'"
  echo "Original Local Signing Key: '$(git config user.signingkey)'"
  echo "Setting git gpg signing key ID to $GIT_SIGNING_KEY."
  git config --global user.signingkey "$GIT_SIGNING_KEY"
  git config user.signingkey "$GIT_SIGNING_KEY"
  echo "Done."
}

kc() {
    kubectl config use-context $1
}

tail_tiller() {
    kubectl --context $1 logs -f --tail=200 -n kube-system deployment/tiller-deploy
}

delete_sessions_from_file() {
    local sessions_file=$1
    jq -R -s -c 'split("\n")[:-1] | { "token": "MINI-ARMAGEDDON", "prefixes": . }' $sessions_file \
    | curl -X POST http://localhost:5005/delete-specific-sessions -H 'Content-Type: application/json' -d @-
}

helmvm() {
    local version=$1
    ln -sf /usr/local/bin/tiller${version} /usr/local/bin/tiller
    ln -sf /usr/local/bin/helm${version} /usr/local/bin/helm
}

sav2csv() {
    R --no-save --silent -e "library(foreign); write.csv(read.spss(file='$1'), file='$2')"
}

# Clone a github repository and then go into the directory created.
#
# Usage:
#   clone repository
# Example:
#   clone bmd/dotfiles
clone() {
    cd ~/git && git clone git@github.com:$1 && cd $(basename "$1")
}

# Print a timestamp and message to stdout
#
# Usage:
#   err message
# Example:
#   err "Your function call is bad and you should feel bad"
err() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [ERROR] $@" >&2
}

# Pretty-print a base64-encoded JSON object.
#
# Usage:
#   j64 data
j64() {
    echo $@ | base64 --decode | jq .
}

# Use JQ with YAML data by converting the YAML to JSON on the fly.
# NB: this will probably perform horribly with large objects, it's just
# meant as a convenience method, not for heavy lifting. You can also
# pass through most JQ options here, although it hasn't been exhaustively
# tested.
#
# Usage:
#   yq data [...options]
yq() {
    yaml2json | jq $@
}

# Create a new directory and change into it
#
# Usage:
#   mcd foo/bar/baz
mcd() {
    mkdir -p "$1" && cd "$1"
}

# Monitor a URL at a defined interval and print out a templated string.
# The format string is passed to `curl -w`.
#
# Usage:
#   monitor_url url interval fmt
# Examples:
#   monitor_url https://google.com
#   monitor_url https://google.com 5 "The status code is: %{http_code}"
monitor_url() {
    curl::loop $@
}

# Sign in to 1Password CLI and set the resulting session token as an
# environment variable.
#
# Usage
#   ops
ops() {
    eval $(op signin my)
}

# Backup my SSH keys to a 1Password vault using the op CLI tool. You
# need to run `ops` to log in to your 1Password account locally before
# this will work.
#
# Usage:
#   backup_ssh_keys
backup_ssh_keys() {
    op::keys::backup $HOME/.ssh "Blue State Digital" "ssh-keys"
}

# Restore my backed-up SSH keys from a 1Password vault You
# need to run `ops` to log in to your 1Password account locally before
# this will work.
#
# Usage:
#   restore_ssh_keys
restore_ssh_keys() {
    op::keys::restore $HOME/.ssh "Blue State Digital" "ssh-keys"
}
