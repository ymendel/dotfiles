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
  FLATTEN_TARGET=${1:-.}

  find $FLATTEN_TARGET -type f -mindepth 2 -exec mv {} $FLATTEN_TARGET \;
  find $FLATTEN_TARGET -type d -d -depth 1 -exec rm -fr {} \;
}
