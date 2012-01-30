grok()
{
  grep -ri "$*" . | grep -v '\.svn' | grep -v '\.git'
}

ip()
{
  ifconfig ${1:-en1} | awk '$1 == "inet" { print $2 }'
}

wiki()
{
  dig +short txt $1.wp.dg.cx
}

flatten()
{
  find . -type f -mindepth 2 -exec mv {} . \;
  find . -type d -d -depth 1 -exec rm -fr {} \;
}
