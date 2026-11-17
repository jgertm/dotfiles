let
  listing = "eza --color auto --group-directories-first";
in
{
  ".." = "cd ..";
  bazel = "bazelisk";
  k = "kubectl";
  gst = "git status";
  watch = "viddy";

  eza = listing;
  ls = listing;
  ll = "${listing} -l";
  la = "${listing} -a";
  lt = "${listing} --tree";
  lla = "${listing} -la";
}
