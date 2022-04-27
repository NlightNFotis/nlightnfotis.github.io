---
layout: post
title: "Distro forking 101: How do you fork a Linux distro?"
date: 2014-07-09 15:04
comments: true
tags: [linux, distro, fork, debian, arch, fedora]
share: true
---

Defining the GNU/Linux distribution
============

If you are here, we can safely assume that you already know what a **GNU/Linux software
distribution** is, but for completion's sake, let's just define so we all have the same context.

A GNU/Linux distribution is a collection of system and application software, packaged together
by the distribution's developers, so that they are distributed in a nicely integrated bundle, ready
to be used by users and developers alike. Software typically included in such a distribution
ranges from a compiler toolchain, to the C library, to filesystem utilities to text editors.

As you can imagine, from the existence of several different GNU/Linux distributions, there are 
multiple ways that you could possibly combine all these different applications and their respective
configurations, not to mention that you could include even more specialised software, depending
on the target audience of the distribution (such as multimedia software for a distribution like 
[Ubuntu Studio](http://ubuntustudio.org/) or penetration testing tools for a distribution such as
[Kali Linux](http://www.kali.org/))

The "f" word
=============

But even with such a great number of different software collections and their respective configurations
there still may not be one that appeals to your specific needs. That's ok though, as you can still
customize each and every distribution to your specific liking. Extensive customization is known to
create a *differentiation point* known as a **potential forking point**.

Forking is a term that has been known to carry negative connotations. [As wikipedia puts it](http://en.wikipedia.org/wiki/Fork_%28software_development%29), 

> the term often implies not merely a development branch, but a split in the developer community
> a form of schism.


Historically, it has also been used as a leverage to coerce a project's developers 
into merging code into their master branches
that they didn't originally want to, or otherwise take a decision that they wouldn't have taken
if not under the pressure of a *"fork"*. But why is it so?

You see, traditionally, forking a project meant a couple of things: For starters, there were now
two, identical projects, competing in the same solution space. 
Those two projects had different development hours and 
features or bug fixes going into them, and eventually, one of the two ended up being obsolete.
Apart from that forking also created an atmosphere of intense competition among the two projects.

However, in 2014, and the advent of the distributed version control systems such as [git](http://git-scm.com/) 
and [mercurial](http://mercurial.selenic.com/) and of the social coding websites such as [Github](http://www.github.com) and [Bitbucket](http://www.bitbucket.org), the term is finally taking
on a more lax meaning, as just another code repository that may or may not enjoy major 
(or even minor, for that matter) development.

Forking a GNU/Linux distribution
--------------------------------------

So, up until now we have discussed what a GNU/Linux distribution is, and what a fork is. 
However, we haven't discussed yet what it means to fork a GNU/Linux distribution.

You see, what differentiates each distro from the other ones, apart from the software collection 
that they contain, is the way in which they provide (and deploy) that software. Yes, we are talking about software packages and their respective package managers. Distributions from the Debian
(.deb) family are using `dpkg` along with `apt` or `synaptic` or `aptitude` or some other higher level
tool. RPM (.rpm) based distributions may use `rpm` with `yum` or `dnf` or  `zypper` or another higher level tool. 
Other distributions, not based on the aforementioned may choose to roll their own configuration
of packages and package managers, with Arch Linux using its own `pacman`, Sabayon uses its `entropy`
package manager, etc.

Now, naturally, if you want to customize an application to your liking, you have many ways in which
you could do that. One of them is downloading the tarball from the upstream's website or ftp 
server, `./configure` it and then `make` and `make install` it. But if you do start customizing
lots of applications this way, it can become tedious and unwieldy too soon. After all, what did
that `make install` install exactly? Will the new update replace those files? What were your
configuration options? Did they replace the files the package manager installed?

In this case, it really pays off to learn **packaging** software for your distribution of choice.
What this means is to learn the format of packages your distribution's package manager accepts
as well as how you could produce them. This way, instead of the `./configure && make && make install` 
cycle, you just have beautiful software packages, that you can control more tightly, you can 
update more easily and you can also distribute them to your friends if you so desire. As an added
bonus, now the package manager also knows about those files, and you can install, remove
or update them much more easily. What's not to like?

After you have created some custom packages, you may also wish to create a repository
to contain them and update straight from that. **Congratulations, you have created your custom
distribution, and a potential fork.** While you are at it, if you really want to fork the distribution,
you could as well take the distribution's `base` packages, customize them, rebuild them, and then
distribute them. **Congratulations again, now you have your true GNU/Linux distribution fork**.

That seems easy. More specifically?
========================

Yes of course. Let's take a look at how you might want to go about forking some well known
GNU/Linux distribution.

Debian
---------

In Debian, your usual procedure if you wish to customize a package is the below:

 * First, you make sure you have the essential building software installed. `apt-get install build-essential devscripts debhelper`
 * Then you need to download the package's build dependencies. `apt-get build-dep $package_name`
 * Now it's time to download it's sources, via `apt-get source $package_name`
 * Proceed with customizing it to your liking (update it, patch the sources, etc)
 * Now it's time to rebuild it. `debuild -us -uc`

Assuming all went fine, you should now have an `$package_name.deb` file in your current 
directory ready to be installed with `dpkg -i $package_name.deb`.

Please take note that the above is not an extensive treatise into debian packaging by any means.
If you want to build custom debian packages, here are some links:

 * [Debian wiki: intro to Debian packaging](https://wiki.debian.org/IntroDebianPackaging)
 * [Roberto C Sanchez: Debian package customization how to](http://people.connexer.com/~roberto/howtos/debcustomize)
 * [Debian wiki: How to package for Debian](https://wiki.debian.org/HowToPackageForDebian)

Now that you have your custom packages, it's time to build a repository to contain them. There 
are many tools you can use to do that, including the official debian package archiving tool
known as `dak`, but if you want a personal repository without too much hassle, it's better if you
use `reprepro`. I won't go to full length on that here, [but instead I will lead you to a very
good guide to do so if you so desire](http://www.debian-administration.org/article/286/Setting_up_your_own_APT_repository_with_upload_support)

Fedora
----------------

Building packages for fedora is a procedure similar to the debian one. Fedora however is more
convenient in one aspect: [It allows you to download a DVD image with all the sources in `.rpm` form
ready for you to customize and rebuild to your tastes.](http://download.fedoraproject.org/pub/fedora/linux/releases/20/Fedora/source/iso/Fedora-20-source-DVD.iso)

Apart from that, the usual procedure is the following:

 * Download the `SRPM` (source RPM) via any means. You could do that using the `yumdownloader` utility, likewise `yumdownloader $package_name`. To use `yumdownloader`, you need
to have `yum-utils` installed.
 * After you have downloaded the `SRPM`, next you have to unpack it: `rpm -i $package_name`
 * Next up, you customize the package to your liking (patch the sources, etc)
 * Finally, you `cd` to the `SPECS` folder, and then `rpmbuild -ba $package.spec`

Again the above mentioned steps may not be 100% correct. If you want to go down this route,
see the following links for more information:
 
 * [Centos wiki: Rebuild SRPM how-to](http://wiki.centos.org/HowTos/RebuildSRPM)
 * [cyberciti: yum Download all Source Packages from RedHat](http://www.cyberciti.biz/faq/yum-download-source-packages-from-rhn/)
 * [bradthemad.org: How to patch and rebuild an RPM package](http://bradthemad.org/tech/notes/patching_rpms.php)
 * [rpm.org: Chapter 11. Building packages](http://www.rpm.org/max-rpm/ch-rpm-build.html)
 * [Fedora wiki: How to create an RPM package](https://fedoraproject.org/wiki/How_to_create_an_RPM_package)

Next up, is the repository creation step. 

 * To create a yum repository, you need to `yum install createrepo`. 
After that you need to create a directory to use as the repository, likewise
`mkdir /var/ftp/repo/Fedora/19/{SRPMS, i386,x86_64)`. 
 * After that you move your i386 packages to `/var/ftp/repo/Fedora/19/i386`, and the rest
of the packages to their respective folders.
 * Next step is adding a configuration file to `/etc/yum.repos.d/` that describes your repository
to yum.

Again, not definitive, and for more information, take a look at these links:

 * [Redhat: Creating a yum repository](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/sec-Yum_Repository.html)
 * [techrepublic: Creating your own yum repository](http://www.techrepublic.com/blog/linux-and-open-source/create-your-own-yum-repository)
 * [Fedora documentation: Creating a yum repository](http://docs.fedoraproject.org/en-US/Fedora/14/html/Deployment_Guide/sec-Creating_a_Yum_Repository.html)

Arch Linux
---------------

[Arch Linux](https://www.archlinux.org/), at least in comparison to `.deb` and `.rpm` package
distribution families is very easy to customize to your liking. That's to be expected though
as Arch Linux is a distribution that sells itself of the customization capabilities it offers to its user.

In essence, if you want to customize a package, the general process is this:

 * Download Arch tarball that contains the `PKGBUILD` file
 * untar the tarball
 * (Optional) download the upstream tarball referenced in the `PKGBUILD`, and modify it
 to your liking
 * run `makepkg` in the folder containing the `PKGBUILD`
 * install (using pacman) the `.xz` file produced after the whole process is finished.

In order to download the official {core | extra | community} packages, you need to run as root
`abs`. This will create a directory tree that contains the files required for building any package 
in the official repositories.

Next up, you can create a custom local repository with the `repo-add` tool, and then proceeding
with editing `/etc/pacman.conf` and adding an entry for your repository there. For more information:

 * [arch-stable: make your own local repo for arch linux](http://arch-stable.blogspot.gr/2012/02/make-your-own-local-repo-for-arch-linux.html)
 * [arch wiki: makepkg](https://wiki.archlinux.org/index.php/makepkg)
 * [arch wiki: pacman tips](https://wiki.archlinux.org/index.php/Pacman_tips)
 * [arch wiki: Arch Build System](https://wiki.archlinux.org/index.php/Arch_Build_System)
 * [arch wiki: Pacman#Repositories](https://wiki.archlinux.org/index.php/Pacman#Repositories)

To fork or not to fork?
===============

Well, that's not an easy question to answer. My opinion is that it's extremely educational to
do a ***soft*** fork, clone the distribution's core repository, and for some time maintain your own
distribution based on it, that is, update and customize all the repositories. Do that for some months,
then go back to using your distribution of choice now that you are enlightened with how it works
under the hood. The reason this is very educational is that it will teach you the ins and outs of
your distribution, teach you about **all** the software in it, how it integrates, what its role is.
It will teach you packaging which is a tremendously undervalued skill, as you can customize
your experience to your liking, and it will make you appreciate the effort going into maintaining
the distribution.

As for doing a **hard** fork, that is creating your own distribution, that you commit to maintaining
it for a long time, my opinion is that it's simply not worth it. Maintaining a distribution, be it
by yourself, or with your friends, is a tremendous amount of work, that's not worth it unless
you have other goals you want to achieve by that. If all you want to do is to customize your 
distribution of choice to your liking, then go ahead, learn packaging for it, customize-package
the applications you want, then create your own repo - but always track the upstream. Diverging
too much from the upstream is not worth the hassle, as you will end up spending more time
maintaining than using the distribution in the end.

tl;dr:
-------

If you want to do a small scale, private fork in order to see what's under the hood of your Linux
distro; by all means go ahead.

If you want to do a large scale, public fork, then take your time to calculate the effort, if it's worth it,
and if you could just help the upstream distribution implement the features you want. 
