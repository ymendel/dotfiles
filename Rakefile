require 'rake'

task :default => 'install'

desc "Hook dotfiles into system-standard positions."
task :install, :mode do |t, args|
  linkables = Dir.glob('*/**{.symlink}')

  skip_all = false
  overwrite_all = args[:mode] == 'force'
  backup_all = false

  linkables.each do |linkable|
    overwrite = false
    backup = false

    file = linkable.split('/').last.chomp('.symlink')
    target = "#{ENV["HOME"]}/.#{file}"

    if File.exists?(target) || File.symlink?(target)
      unless skip_all || overwrite_all || backup_all
        puts "File already exists: #{target}, what do you want to do? [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all"
        case STDIN.gets.chomp
        when 'o' then overwrite = true
        when 'b' then backup = true
        when 'O' then overwrite_all = true
        when 'B' then backup_all = true
        when 'S' then skip_all = true
        when 's' then next
        end
      end
      FileUtils.rm_rf(target) if overwrite || overwrite_all
      `mv "#{target}" "#{target}.backup"` if backup || backup_all
    end
    `ln -s "$PWD/#{linkable}" "#{target}"`
  end


  installs = Dir.glob('*/**{.install}')

  installs.each do |install|
    system(install)
  end
end

desc "Remove dotfiles from system-standard positions."
task :uninstall do
  Dir.glob('**/*.symlink').each do |linkable|

    file = linkable.split('/').last.chomp('.symlink')
    target = "#{ENV["HOME"]}/.#{file}"

    # Remove all symlinks created during installation
    if File.symlink?(target)
      FileUtils.rm(target)
    end

    # Replace any backups made during installation
    if File.exists?("#{target}.backup")
      `mv "#{target}.backup" "#{target}"` 
    end
  end
end

desc "Hook scripts into system-standard positions."
task :install_scripts, :mode do |t, args|
  script_dir = "#{ENV["HOME"]}/Library/Scripts"

  linkables = Dir.glob('scripts/*/**{.scpt}')

  skip_all = false
  overwrite_all = args[:mode] == 'force'
  backup_all = false

  linkables.each do |linkable|
    overwrite = false
    backup = false

    targets = []

    linkable_split = linkable.split('/')

    file = linkable_split[1..-1].join(' ')
    targets.push "#{script_dir}/#{file}"

    if File.directory?(linkable_split.first(2).join('/'))
      target_dir = "#{ENV["HOME"]}/Library/#{linkable_split[1]}/Scripts"
      if File.directory?(target_dir)
        file = linkable_split[2..-1].join(' ')
        targets.push "#{target_dir}/#{file}"
      end
    end

    targets.each do |target|
      if File.exists?(target) || File.symlink?(target)
        unless skip_all || overwrite_all || backup_all
          puts "File already exists: #{target}, what do you want to do? [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all"
          case STDIN.gets.chomp
          when 'o' then overwrite = true
          when 'b' then backup = true
          when 'O' then overwrite_all = true
          when 'B' then backup_all = true
          when 'S' then skip_all = true
          when 's' then next
          end
        end
        FileUtils.rm_rf(target) if overwrite || overwrite_all
        `mv "#{target}" "#{target}.backup"` if backup || backup_all
      end
      `ln "$PWD/#{linkable}" "#{target}"`
    end
  end
end
