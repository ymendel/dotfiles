grok()
{
  grep -ri "$*" . | grep -v '\.svn' | grep -v '\.git'
}

files_with()
{
    grok $* | cut -d : -f 1 | sort | uniq
}

ip()
{
  ifconfig ${1:-en0} | awk '$1 == "inet" { print $2 }'
}

mac()
{
  ifconfig ${1:-en0} | awk '$1 == "ether" { print $2 }'
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

go_to()
{
  loc=`which $1`
  cd `dirname $loc`
}
alias gt=go_to
