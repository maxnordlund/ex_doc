defmodule ExDoc.Formatter.EPUB.TemplatesTest do
  use ExUnit.Case, async: true

  alias ExDoc.Formatter.HTML
  alias ExDoc.Formatter.EPUB.Templates

  defp source_url do
    "https://github.com/elixir-lang/elixir"
  end

  defp homepage_url do
    "http://elixir-lang.org"
  end

  defp doc_config do
    %ExDoc.Config{
      project: "Elixir",
      version: "1.0.1",
      source_root: File.cwd!,
      source_url_pattern: "#{source_url()}/blob/master/%{path}#L%{line}",
      homepage_url: homepage_url(),
      source_url: source_url(),
    }
  end

  defp get_module_page(names) do
    mods = names
           |> ExDoc.Retriever.docs_from_modules(doc_config())
           |> HTML.Autolink.all()

    Templates.module_page(doc_config(), hd(mods))
  end

  ## MODULES

  test "module_page generates only the module name when there's no more info" do
    node = %ExDoc.ModuleNode{module: XPTOModule, moduledoc: nil, id: "XPTOModule"}
    content = Templates.module_page(doc_config(), node)

    assert content =~ ~r{<title>XPTOModule [^<]*</title>}
    assert content =~ ~r{<h1 id="content">\s*XPTOModule\s*}
  end

  test "module_page outputs the functions and docstrings" do
    content = get_module_page([CompiledWithDocs])

    assert content =~ ~r{<title>CompiledWithDocs [^<]*</title>}
    assert content =~ ~r{<h1 id="content">\s*CompiledWithDocs\s*}
    assert content =~ ~r{moduledoc.*Example.*CompiledWithDocs\.example.*}ms
    assert content =~ ~r{example/2.*Some example}ms
    assert content =~ ~r{example_without_docs/0.*<section class="docstring">.*</section>}ms
    assert content =~ ~r{example_1/0.*Another example}ms

    assert content =~ ~s{<div class="detail" id="example_1/0">}
    assert content =~ ~s{example(foo, bar \\\\ Baz)}
  end

  test "module_page outputs the types and function specs" do
    content = get_module_page([TypesAndSpecs, TypesAndSpecs.Sub])

    mb = "http://elixir-lang.org/docs/stable"

    public_html =
      ~S[<a href="#t:public/1">public(t)</a> :: {t, ] <>
      ~s[<a href="#{mb}/elixir/String.html#t:t/0">String.t</a>, ] <>
      ~S[<a href="TypesAndSpecs.Sub.html#t:t/0">TypesAndSpecs.Sub.t</a>, ] <>
      ~S[<a href="#t:opaque/0">opaque</a>, :ok | :error}]

    ref_html = ~S[<a href="#t:ref/0">ref</a> :: ] <>
               ~S[{:binary.part, <a href="#t:public/1">public(any)</a>}]

    assert content =~ ~s[<a href="#t:public/1">public(t)</a>]
    refute content =~ ~s[<a href="#t:private/0">private</a>]
    assert content =~ public_html
    assert content =~ ref_html
    refute content =~ ~s[<strong>private\(t\)]
    assert content =~ ~s[A public type]
    assert content =~ ~s[add(integer, <a href="#t:opaque/0">opaque</a>) :: integer]
    refute content =~ ~s[minus(integer, integer) :: integer]
  end

  test "module_page outputs summaries" do
    content = get_module_page([CompiledWithDocs])
    assert content =~ ~r{<div class="summary-signature">\s*<a href="#example_1/0">}
  end

  test "module_page contains links to summary sections when those exist" do
    content = get_module_page([CompiledWithDocs, CompiledWithDocs.Nested])
    refute content =~ ~r{types_details}
  end

  ## BEHAVIOURS

  test "module_page outputs behavior and callbacks" do
    content = get_module_page([CustomBehaviourOne])
    assert content =~ ~r{<h1 id="content">\s*CustomBehaviourOne\s*<small>behaviour</small>\s*</h1>}m
    assert content =~ ~r{Callbacks}
    assert content =~ ~r{<div class="detail" id="c:hello/1">}

    content = get_module_page([CustomBehaviourTwo])
    assert content =~ ~r{<h1 id="content">\s*CustomBehaviourTwo\s*<small>behaviour</small>\s*</h1>}m
    assert content =~ ~r{Callbacks}
    assert content =~ ~r{<div class="detail" id="c:bye/1">}
  end

  ## PROTOCOLS

  test "module_page outputs the protocol type" do
    content = get_module_page([CustomProtocol])
    assert content =~ ~r{<h1 id="content">\s*CustomProtocol\s*<small>protocol</small>\s*}m
  end
end
