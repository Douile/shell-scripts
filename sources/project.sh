#!/bin/sh

project() {
  project=$(find ~/Code -name ".git" -type d | sed 's/.git$//' | fzf --preview 'ls -la {+1}')
  cd "$project"
  git pull
}
