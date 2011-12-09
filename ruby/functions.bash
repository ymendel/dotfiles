rvm_current()
{
  rvm info | sed -n '2,1s/:$//p'
}
