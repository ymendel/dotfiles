grok() {
  grep -ri "$*" . | grep -v '\.svn'
}

ip()
{
  ifconfig ${1:-en1} | awk '$1 == "inet" { print $2 }'
}

wiki() {
  dig +short txt $1.wp.dg.cx
}
