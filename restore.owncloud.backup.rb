=begin

restore.backup.rb

USAGE:

	ruby restore.backup.rb "/home/user/directory/to/restore"
	ruby restore.backup.rb "directory/to/restore"

DESCRIPTION:

All ownCloud user files within the specified directory are restored
using previous version history. This is useful when a user deletes
all their files on accident.

Previous versions of files are stored in the user/files_versions directory
They are named like:
	filename.ext.vUNIXTIMESTAMP
	Template.csv.v1352164267

This script loops over all of the file versions, finds the most recent, and
copies it to a RESTORED directory located in the same directory as the
files_versions/folder you're restoring.
	files_versions/Documents ->	files_versions/Documents\ RESTORED

I would advise copying the directory within files_versions you would like to
restore and work with it somewhere else. Then match the files_versions
directory with the new restored directory so the user can still revert.

=end

require 'fileutils'

def restore_directory(dir, restored_loc)

	path = File.absolute_path(dir)
	new_path = File.absolute_path(restored_loc)

	unique_file = Hash.new
	
	Dir.foreach(dir) do |item|
		next if item == "." or item == ".."
		if File.directory?(File.join(path, item))
			
			if !File.directory?(File.join(new_path, item))
				Dir.mkdir(File.join(new_path, item), 0755)
			end
			restore_directory(File.join(path, item), File.join(restored_loc, item))
		elsif is_numeric?(item[-10..-1])
			filename = item[0..-13]
			restore_point = item[-12..-1]
			
			if (unique_file.has_key?(filename) && unique_file[filename] < restore_point) || !unique_file.has_key?(filename)
				unique_file[filename] = restore_point
			end
		end
	end
	unique_file.each_pair do |key, value|
		src = File.join(path, key + value)
		dst = File.join(new_path, key)
		FileUtils.cp(src, dst)
	end
	
end

# http://rosettacode.org/wiki/Determine_if_a_string_is_numeric#Ruby
def is_numeric?(s)
    !!Float(s) rescue false
end

if !ARGV.empty? and File.directory?(ARGV[0])
	restored_loc = File.basename(ARGV[0]) << " RESTORED"
	if !File.directory?(restored_loc)
		Dir.mkdir(restored_loc, 0755)
	end
	restore_directory(ARGV[0], restored_loc)
else
	print "'",ARGV[0], "' is not a valid directory. "
	print "Please specify the directory you would like to restore.\n"
	print "It can be either relative: folder/name, or absolute: /home/user/folder/name\n"
end

