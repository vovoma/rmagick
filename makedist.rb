#! /usr/local/bin/ruby -w

# Make the RMagick package directory tree.
# Start from the root directory, i.e. RMagick-1.2.0
require 'ftools'
require 'find'

TAG = ARGV[0] || 'HEAD'
puts "Exporting CVS #{TAG}"

def echosys(cmd)
    puts cmd
    err = `#{cmd}`
    if $? != 0
        puts err
        raise StandardError, "#{cmd} failed with rc = #{$?}"
    end
end

def cvsexport(file, from=nil, to=nil)
    to ||= from || '.'
    file = "#{from}/#{file}" if from && from != '.'
    echosys "cvs export -r #{TAG} -d #{to} RubyMagick/#{file}"
end

def cvsexportmodule(mod)
    echosys "cvs export -r #{TAG} -d #{mod} RubyMagick/#{mod}"
end

def configure_ac()
    version = $distdir.sub(/RMagick-/,"")
    begin
        File.open("configure.ac") do |in2|
            File.open("_configur.ac", "w") do |out|
                in2.each do |line|
                    line.gsub!(/x\.y\.z/, version)
                    out.write(line)
                end
            end
        end
    rescue
        File.delete("_configur.ac")
        raise
    end
    File.move("_configur.ac", "configure.ac")
end

def readme(name)
    tempname = "_#{name}"
    version = $distdir.sub(/RMagick-/,"")
    now = Time.new
    now = now.strftime("%m/%d/%y")
    begin
        File.open(name) do |in2|
            File.open(tempname, "w") do |out|
                in2.each do |line|
                    if %r{MAJOR.MINOR.TEENY}.match(line)
                        line.sub!(%r{MAJOR.MINOR.TEENY}, version)
                    end
                    if %r{YY/MM/DD}.match(line)
                        line.sub!(%r{YY/MM/DD}, now)
                    end
                    out.write(line)
                end
            end
        end
    rescue
        File.delete(tempname)
        raise
    end
    File.move(tempname, name)
end

if TAG != 'HEAD'
    $distdir = TAG.tr('_-','-.') # replace tag punctuation with directory punctuation
                                # For example, RMagick_1-1-0 becomes RMagick-1.1.0
else
    $distdir = 'RMagick-x.y.z'   # Testing
end

cwd = Dir.getwd
system("rm -rf #{$distdir}")
File.makedirs($distdir)
begin
    Dir.chdir($distdir)

    # Make the directory tree
    File.makedirs("doc/ex/images")
    File.makedirs("ext/RMagick")
    File.makedirs("lib")

    cvsexport "install.rb"
    cvsexport "configure.ac"
    cvsexport "Makefile.in"
    cvsexport "metaconfig.in"
    cvsexport "post-setup.rb"
    cvsexport "post-install.rb"
    cvsexport "post-clean.rb"
    cvsexport "uninstall.rb"
    cvsexport "README.txt"
    cvsexport "README.html"
    cvsexport "ChangeLog"

    cvsexport "comtasks.html", "doc"
    cvsexport "constants.html", "doc"
    cvsexport "draw.html", "doc"
    cvsexport "fill.html", "doc"
    cvsexport "ilist.html", "doc"
    cvsexport "imageattrs.html", "doc"
    cvsexport "image.html", "doc"
    cvsexport "imusage.html", "doc"
    cvsexport "index.html", "doc"
    cvsexport "info.html", "doc"
    cvsexport "magick.html", "doc"
    cvsexport "rubymgen.css", "doc"
    cvsexport "struct.html", "doc"
    cvsexport "usage.html", "doc"

    echosys("chmod 0644 doc/*.html")

    cvsexport "extconf.rb.in", '.',"ext/RMagick"
    cvsexport "rmfill.c", '.',"ext/RMagick"
    cvsexport "rmilist.c", '.',"ext/RMagick"
    cvsexport "rmimage.c", '.',"ext/RMagick"
    cvsexport "rminfo.c", '.',"ext/RMagick"
    cvsexport "rmmain.c", '.',"ext/RMagick"
    cvsexport "rmutil.c", '.',"ext/RMagick"
    cvsexport "rmagick.h", '.',"ext/RMagick"
    cvsexport "rmagick_config.h.in", '.', "ext/RMagick"

    cvsexport "RMagick.rb", '.', "lib"

    cvsexportmodule "examples"
    echosys("chmod 0644 examples/*")

    cvsexportmodule "doc/ex"
    echosys("chmod 0644 doc/ex/*.rb")
    cvsexportmodule "doc/ex/images"
    echosys("chmod 0644 doc/ex/images/*")

    configure_ac()
    readme('README.html')
    readme('README.txt')

    echosys("autoconf")
#    File.delete("configure.ac")
    echosys('rm -rf autom4te.cache')

    now = Time.new
    now = now.strftime("%H:%M:%S %m/%d/%y")

    File.open("ext/RMagick/MANIFEST", "w") { |f|
        puts "...generating MANIFEST"
        f.puts "MANIFEST for #{$distdir} - #{now}\n\n"
        Find.find('.') { |name|
            next if File.directory? name
            name.sub!(%r{\./},'')
            f.puts name
            }
        }
ensure
    Dir.chdir(cwd)
end

echosys("tar cvfz #{$distdir}.tar.gz #{$distdir}")
exit
