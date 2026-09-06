# Figure targets: blog/images/<name>.tex -> _build/tikzgen/<name>.svg.
#
# custom_target outputs carry no path segments; declaring them from this
# subdirectory is what puts them under _build/tikzgen/, where the Org
# sources link them.  The tex sources arrive as absolute paths (globs are
# rooted at the source root).  `svgs` is consumed by the export edge in the
# parent meson.build.

svgs = []
foreach tex : texsrc
  svg = fs.replace_suffix(tex, '.svg')
  svgs += custom_target(
    fs.name(svg),
    input: tex,
    output: fs.name(svg),
    command: [tikzbuild, '@INPUT@', '@OUTPUT@'],
    build_by_default: true,
  )
endforeach
