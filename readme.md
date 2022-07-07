# DocFX TOC Generator

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/docfx-toc-generator)](https://www.powershellgallery.com/packages/docfx-toc-generator/)

This fork adds support for ToC item name generation based on a `name` attribute or just the filename (sanitized and turned into a "title" automatically) if nothing is manually passed. It also adds the ability to create a blank `index.md` file (e.g. `touch index.md`) in any directory to have it added to the ToC without having to add any content. This is useful for just making ToC folders.

## What is this?

This script is used to generate `toc.yml` file for every folder in documentation project.

## Prerequesties

First you should install `powershell-yaml`

```powershell
Install-Module powershell-yaml
```

## Installing Module

⚠ THIS MODULE DOES NOT WORK WITH **WINDOWS POWERSHELL**

⚠ MAKE SURE YOU HAVE [**POWERSHELL CORE**](https://github.com/PowerShell/PowerShell) INSTALLED.

```powershell
Install-Module -Name docfx-toc-generator
```

## FAQ

### How to use this module?

Install the module, then run `Build-TocHereRecursive` function in the root of the docfx project, besides `docfx.json`

### What is the limitation?

This module doesn't generate the root TOC (root of folder besides `docfx.json`), you should create that file yourself.

### What if I want to ignore a folder?

Simply create an empty `.nodoc` file in the root of the folder.

### How to give markdown files name, href, items and order?

The `href` and `items` property of item in `yaml` file is created automatically.
For naming and order use Front Matter style `yaml` meta data in markdown file:

```
---
name: Sample Page
order: 100 # higher has more priority
---

# Sample Page
```

### How to create hierarchy?

This module puts every non-index file(non-`index.md`) in the toc, then it includes every `index.md` files in subfolder in the toc, and other files in subfolders in the `items` subchild of `index` file. For example if you have such hierarchy:

```
|-- root-doc.md
|-- some-other-root-doc.md
>-- MyTopic
  |---- somefile.md
  |---- index.md
|
>-- OtherTopic
  |-- index.md
  |-- hello.md
```

This toc will be generated:

```yml
- name: Root Doc
  href: root-doc.md
- name: Some Other Root Doc
  href: some-other-root-doc.md
- name: My Topic
  href: MyTopic/index.md
  items:
    - name: Some File
      href: MyTopic/somefile.md
- name: Other Topic
  href: OtherTopic/index.md
  items:
    - name: Hello World!
      href: OtherTopic/hello.md
```

If you want to ignore content of an index and remove its `href` attribute from toc file, simply add `nocontent: true` to the front matter:

## Table of Front-Matter Tags

| Attribute | Description                                                                                               | Type    |
| --------- | --------------------------------------------------------------------------------------------------------- | ------- |
| name      | Gives document a name in toc                                                                              | string  |
| order     | Gives order of rendering to the document in toc (higher number has more priority and comes top of others) | int     |
| nocontent | Ignores content and remove the `href` attribute in toc                                                    | boolean |
