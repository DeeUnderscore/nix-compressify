#!/usr/bin/env nu
# target: nu 0.99.1

def compressify-impl [
  args: record
  new_ext: string
  command_closure: closure
] {
  mkdir $args.outdir
  (ls -a ($"($args.indir)/**/*" | into glob)
  | where $it.type == "file"
  | par-each --threads $args.jobs {|it|
    let input_file = ($it.name | path parse)
    if $input_file.extension in $args.fileExtensions {

      # figure out source subdir and get corresponding subdir under outdir
      let target_dir = (
        $args.outdir
        | path join (
          $input_file.parent
          | path relative-to $args.indir
        )
      )

      # indir/subdir/file.ext → outdir/subdir/file.ext.new_ext
      let target_file = (
        $input_file
        | update parent $target_dir
        | update extension {|it| $"($it.extension).($new_ext)"}
      )

      mkdir $target_dir

      let res = (try {
        do $command_closure ($input_file | path join) ($target_file | path join)
      } catch {|e|
        print -e $"Problem compressing ($target_file | path join)"
        if $e.exit_code != 0 {
          exit $e.exit_code
        }
      })

      let threshold_size = (
        (ls ($input_file | path join) | get 0.size)
        * $args.threshold
      )

      let target_file_size = (ls ($target_file | path join) | get 0.size)

      if (
         $target_file_size >= $threshold_size
      ) {
        print -e $"Removing ($target_file | path join): Size is over threshold \(($target_file_size) >= ($threshold_size); threshold is ($args.threshold)\)."
        rm --permanent ($target_file | path join)
      }
    }
  }
  )
}

def brotlify [
  args: record
] {
  compressify-impl $args "br" {|infile, outfile|
    brotli -v --no-copy-stat --best $infile -o $outfile
  }
}

def zopflify [
  args: record
] {
  compressify-impl $args "gz" {|infile, outfile|
    # zopfli verbose mode is a bit too verbose
    print -e $"Compressing ($infile)"
    zopfli $"--i($args.level)" $infile -c out> $outfile
  }
}

def main [ ] {
  let args = (open $env.NIX_ATTRS_JSON_FILE)
  let compressifyArgs = ($args.compressifyArgs
    | reject "command"
    | insert "outdir" $args.outputs.out
    | insert "indir" $args.src
    | insert "jobs" ($env.NIX_BUILD_CORES | into int)
  )
  if $args.compressifyArgs.command == "brotlify" {
    brotlify $compressifyArgs
  } else if $args.compressifyArgs.command == "zopflify" {
    zopflify $compressifyArgs
  } | ignore
}
