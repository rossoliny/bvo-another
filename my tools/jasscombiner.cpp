#include <iostream>
#include <sstream>
#include <fstream>
#include <string>

using namespace std;

const string EXE_NAME = "jass_combiner";
const string DEFAULT_OUTPUT_FILE = "jasscombine.j";

string output_filename = DEFAULT_OUTPUT_FILE;

void print_flag(string flag, string desc)
{
	cout << "\t" << flag << ":\t" << desc;
}

void print_usage()
{
	cout << "Usage: " << EXE_NAME << " <flags> {coma separated list of files}" << endl;
	cout << "\nIMPORTANT: order of files must match fucntion declaration order, otherwise jass script will not work\n";

	cout << "\nFlags: " << endl;
	print_flag("-o <output file>", "specifies the name of output file, default is \"" + DEFAULT_OUTPUT_FILE + "\"");
	//print_flag("-i <input files>", "specifies the input files, enter comma separated list of file names");
}

int process_flags(int& argc, char** argv)
{
	int input_begin = 1;

	for(int i = 1; i < argc; i++)
	{
		string arg = argv[i];

		if(arg == "-o")
		{
			output_filename = argv[i + 1];
			input_begin = i + 2;
			argc -= 2;
			i++;
		}
	}

	return input_begin;
}

void finish(int exit_code)
{
	exit(exit_code);
}

void print_file_start(string file_name, ostream& out)
{
	out << "// #begin file: \"" << file_name << "\"\n";
}

void print_file_end(string file_name, ostream& out)
{
	out << "// #end file: \"" << file_name << "\"\n\n";
}

void print_file_empty(string file_name, ostream& out)
{
	out << "\n// #empty file: \"" << file_name << "\"\n\n";
}

void file_open_fail(string file_name)
{
	cerr << "could not open \"" << file_name << "\"" << ", probably it's already used by another proccess.";
	cerr << endl;
	finish(-1);
}


stringstream globals;

void proccess_globals(string& filename, ifstream& file)
{
	globals << "\n// #begin globals from: \"" + filename + "\"\n";

	string line;

	while(getline(file, line))
	{
		if(line == "endglobals")
		{
			break;
		}

		globals << line << "\n";
	}

	globals << "// #end globals from: \"" + filename + "\"\n";
}

void proccess_single_file(string& input_filename, ostream& output_file)
{
	ifstream input_file(input_filename);

	if(input_file.is_open())
	{
		bool contains_globals = false;

		string line;
		stringstream out;

		if(getline(input_file, line))
		{
			print_file_start(input_filename, out);
			do
			{
				if(line == "globals")
				{
					proccess_globals(input_filename, input_file);
				}
				else
				{
					out << line << '\n';
				}
			} while(getline(input_file, line));
			print_file_end(input_filename, out);
		}
		else
		{
			print_file_empty(input_filename, out);
		}

		output_file << out.rdbuf() << endl;
		output_file.flush();

		input_file.close();
	}
	else
	{
		file_open_fail(input_filename);
	}

}

void write_globals(ostream& output_globals)
{
	output_globals << "globals\n";
	output_globals << globals.rdbuf() << endl;
	output_globals << "endglobals\n\n";
}

void proccess_files(int count, char** filenames)
{
	ofstream output_file(output_filename);
	stringstream functions;

	if(!output_file.is_open())
	{
		file_open_fail(output_filename);
	}

	for(int i = 0; i < count - 1; i++)
	{
		string file_name = filenames[i];

		proccess_single_file(file_name, functions);
	}

	write_globals(output_file);
	output_file << functions.rdbuf() << endl;
	output_file.flush();
	output_file.close();
}

int main(int argc, char** argv)
{
	if(argc < 2)
	{
		print_usage();
		finish(-1);
	}
	
	int files_begin = process_flags(argc, argv);
	
	proccess_files(argc, &argv[files_begin]);

}
