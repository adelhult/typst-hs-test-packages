#let nada(ignore_me) = {
    "foo"
}
// removing space after $ works
#let w = nada(x => $x$ + x)
