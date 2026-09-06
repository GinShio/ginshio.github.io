project('blog', version: '1.0')

fs = import('fs')

# TikZ sources, one figure per file: blog/images/<name>.tex -> _build/tikzgen/<name>.svg
# The output directory is pinned by the Org sources, which link the figures
# as ../../_build/tikzgen/<name>.svg.
texsrc = run_command('find', meson.current_source_dir() / 'blog/images',
                     '-maxdepth', '1', '-type', 'f', '-name', '*.tex',
                     check: true).stdout().split()

tikzbuild = files('scripts/tikz-build.sh')
subdir('tikzgen')

# Org sources of the posts.  -type f excludes emacs lock symlinks (#.foo.org),
# which appear while a post is open in an editor session.
orgsrc = run_command('find', meson.current_source_dir() / 'blog', '-type', 'f', '-name', '*.org',
                     check: true).stdout().split()

# Hugo site inputs: only the tracked sources.  The generated paths
# (content/posts, static/images, static/ltximg, resources/) must NOT be
# inputs: the export writes them as side effects, so after a cleanall they
# would be missing inputs to ninja.  Their freshness reaches the site edge
# transitively through export.stamp, which is newer whenever the export
# re-ran.
sitesrc = run_command('find', meson.current_source_dir() / 'publisher/hugo', '-type', 'f',
                      '!', '-path', '*/resources/*', '!', '-name', '.hugo_build.lock',
                      '!', '-path', '*/content/posts/*', '!', '-path', '*/static/images/*',
                      '!', '-path', '*/static/ltximg/*',
                      check: true).stdout().split()

# One emacs run exports every stale post, then stamps.  ninja reruns the
# edge only when an Org source, a figure, or the exporter is newer than the
# stamp; the exporter itself re-checks per file, including the linked
# figures the Org file's own mtime cannot see.  The exporter takes no
# arguments: export-hugo.sh starts batch emacs under the ginshio
# configuration, export-hugo.el derives the root from its own location and
# writes _build/export.stamp.
export_stamp = custom_target(
  'hugo-export',
  input: orgsrc + svgs + files('scripts/export-hugo.sh', 'scripts/export-hugo.el'),
  output: 'export.stamp',
  command: [files('scripts/export-hugo.sh')],
  build_by_default: true,
)

# The site build runs hugo into the pages repository _build/hugogen and
# stamps; ninja reruns it when the export, the site sources, or the hugo
# theme moved.
custom_target(
  'hugo-site',
  input: [export_stamp] + sitesrc + files('scripts/hugo-site.sh'),
  output: 'site.stamp',
  command: [files('scripts/hugo-site.sh'), '@SOURCE_ROOT@', '@OUTPUT@'],
  build_by_default: true,
)

run_target('cleanall',
  command: [files('scripts/meson-clean.sh'), '@SOURCE_ROOT@'])
