# Clone the Typst packages repo

```
git submodule update --init --recursive
```

# Run the test-suite

```sh
cabal test --test-show-details=streaming
```

# Results

Running the `typst-hs` parser on all `.typ` files in the packages repo results
in:

```
Cases: 1246 Tried: 1246 Errors: 0 Failures: 76
```

See `test/counter-examples` shruken tests that work in the Rust Typst compiler
but not in the Haskell implementation.
