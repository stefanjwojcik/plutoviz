using plutoviz
using Documenter

DocMeta.setdocmeta!(plutoviz, :DocTestSetup, :(using plutoviz); recursive=true)

makedocs(;
    modules=[plutoviz],
    authors="Stefan Wojcik",
    repo="https://github.com/stefanjwojcik/plutoviz.jl/blob/{commit}{path}#{line}",
    sitename="plutoviz.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
