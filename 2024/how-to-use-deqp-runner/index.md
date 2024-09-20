# How To Use Mesa's test tool: deqp-runner


[deqp-runner](https://gitlab.freedesktop.org/mesa/deqp-runner) is a series of tools written by mesa developers for running vulkan
and opengl quality test case programs. It can run in parallel and robustly [dEQP](https://github.com/KhronosGroup/VK-GL-CTS)
(draw-element quality program), [piglit](https://gitlab.freedesktop.org/mesa/piglit), SkQP (Skia Quality Program), and so on.

In my experience, when running large dEQP test cases, your own changes may cause
umd (user mode driver) to _fail_, _crash_, _timeout_, or _hang_. If you simply use
`deqp-vk`, the khronos testcases program for vulkan, the test will stop when umd
throws unrecoverable error. And we cannot easily get the results that new
failures based on the previous version.

Yes, we don't need to write a new / own scripts to handle testcase stopping.
deqp-runner help us to do it:

-   Parallel running cases, it's very useful if we need to run a huge set
-   Run next case and report this case's state if an unrecoverable error is
    thrown
-   automatically compare the differences between baseline and current version


## Build {#build}

The tool is written in rust-lang, and is very easy to get and build (compare
with C++, **LoL**).

```shell
git clone https://gitlab.freedesktop.org/mesa/deqp-runner.git
cd deqp-runner
cargo build --release --target-dir _build
```

The executable file is generated in `_build/release`, `deqp-runner` and
`piglit-runner` are very useful for me.


## Usage for dEQP {#usage-for-deqp}

We run dEQP cases via `deqp-runner`:

```fundamental
deqp-runner run \
    [runner options...] \
    -- \
    [deqp program options...]
```

For running dEQP testcases, we have some important arguments in `deqp-runner`:

deqp
: dEQP executable file

jobs
: how many threads running in parallel

output
: where the results are stored

timeout
: the run is terminted if the given number of seconds is exceeded

caselist
: a list of testcase list files

env
: a list of test run-time environment variables, e.g. `VK_DRIVER_FILES`,
    `MESA_LOADER_DRIVER_OVERRIDE`

If you run a base driver first, you can set **baseline** to failures of base,
`deqp-runner` will automatically compare current results with baseline.

If you just want to run a subset of given case lists, **include-tests** help us to
do it, testcases are skipped if testcase name is not match in this option.

For example, I use command a lot:

```shell
deqp-runner run \
    --deqp deqp-vk \
    --caselist {binding-mode,descriptor-indexing}.txt compute.txt image/*.txt \
    --env VK_DRIVER_FILES=vulkan/icd.d/radeon_icd.x86_64.json \
    --jobs $(awk -v CPUS=$(lscpu -e |wc -l) 'BEGIN{print int((CPUS-1)*0.8)}') \
    --output deqp-vk_$(date --iso-8601="date") \
    --timeout 240.0 \
    -- \
    --deqp-log-images=disable \
    --deqp-log-shader-sources=disable \
    --deqp-log-decompiled-spirv=disable \
    --deqp-shadercache=disable
```

Running opengl dEQP is similar to vulkan:

```shell
deqp-runner run \
    --deqp glcts \
    --caselist gl/khronos_mustpass/*-main.txt \
    --env LD_LIBRARY_PATH=opengl MESA_LOADER_DRIVER_OVERRIDE=radeonsi \
    --jobs 4 \
    --output deqp-gl_$(date --iso-8601="date") \
    --timeout 240.0 \
    -- \
    --deqp-gl-config-name=rgba8888d24s8ms0 \
    --deqp-surface-{height,width}=256 \
    --deqp-visibility=hidden
```


## Output {#output}

The main output files we should focus on:

-   **results.csv** that all testcases status in here
-   **failures.csv** that all failures, crashes, timeouts in here

According to source code, the test status as following:

| test status          | runner status |
|----------------------|---------------|
| Pass                 | Pass          |
| Fail                 | Fail          |
| QualityWarning       | Warn          |
| CompatibilityWarning | Warn          |
| Pending              | Fail          |
| NotSupported         | Skip          |
| ResourceError        | Fail          |
| InternalError        | Fail          |
| Crash                | Crash         |
| DeviceLost           | Crash         |
| Timeout              | Timeout       |
| Waiver               | Warn          |
| Not found testcase   | Missing       |

If using baseline, maybe get new status:

| runner status         | means                                  |
|-----------------------|----------------------------------------|
| ExpectedFail          | Failed in baseline and current         |
| UnexpectedImprovement | Status in current better than baseline |

If any results came back with an unexpected failure, run the caselist again to
see if we get the same results, and mark any changing results as flaky tests. In
results file, it called **Flake**.

Easily report the flake testcases in current running:

```shell
awk -F, '$2 == "Flake"{print $1}' results.csv >flakes.txt
```


## Usage for piglit {#usage-for-piglit}

Similar to `deqp-runner`, piglit must set profile mode what is `*.xml.gz` in tests
folder. And using **piglit-folder** instead of _deqp_ executable file.

For example:

```shell
piglit-runner run \
    --jobs 2 --profile quick --timeout 300 \
    --piglit-folder piglit \
    --output piglit_$(date --iso-8601="date") \
    --
```

Different with other runner, testcase's name looks strange in result file. For
example, `asmparsertest@arbfp1.0@cos-03.txt`. In fact, the name is from profile.

