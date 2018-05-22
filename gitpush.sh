git add .
read -p "输入git备注信息:" -t 30 commitMsg
if [ "$commitMsg" = "" ]; then
  echo "new host name is empty, not set new hostname."
  exit 0
fi
git commit -m $commitMsg
git push origin hexo
