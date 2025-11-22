#!/bin/bash
# Make login shells load the main bashrc
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
