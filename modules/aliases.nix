let
  listing = "eza --color auto --group-directories-first";
in
{
  bazel = "bazelisk";
  k = "kubectl";
  rpn = "emacs -Q -nw -f full-calc";

  eza = listing;
  ls = listing;
  ll = "${listing} -l";
  la = "${listing} -a";
  lt = "${listing} --tree";
  lla = "${listing} -la";
}
