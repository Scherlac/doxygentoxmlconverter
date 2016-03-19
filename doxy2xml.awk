#!/bin/gawk

BEGIN {

	IS_COMMENT=0;
	COMMENT_BLOCK=0;
	
	translate["\\fn"]     = "skip";
	translate["\\def"]    = "skip";
	translate["\\class"]  = "skip";
	translate["\\enum"]   = "skip";
	translate["\\struct"] = "skip";
	translate["\\author"] = "skip";
	translate["\\brief"]  = "summary";
	translate["\\param"]  = "param";
	translate["\\return"] = "returns";

	reset();


}

function reset()
{
	LINE_START="    ";
	COMMENT = "";
}

function getcomment(row)
{
	COMMENT = COMMENT row;
}

function putcomment()
{
	# we place the comment if we have some
	if (length(COMMENT)>4)
	{
		tmp = COMMENT;
		# removes start of the comment block
		tmp = gensub(/\/\*+\s+/," ","g", tmp);

		# removes end of the comment block
		tmp = gensub(/\s+\*+\//," ","g", tmp);

		# removes duplicated white spaces
		tmp = gensub(/[* \t]+/," ","g", tmp);

		# removes leading and tail white spaces
		tmp = gensub(/^\s*/, "","", tmp);
		tmp = gensub(/\s*$/, "","", tmp);
		num = split(tmp, comments, /\s*\\\w+\s*/, tags);

		#print "/// DOXY (" num "): " tmp
		for (i=1;i<num;i++)
		{
			#print "/// TAG: >>" gensub("[ ]*", "", "g", tags[i]) "<<";
			#print "/// COMMENT: >>" comments[i+1] "<<";

			# this is the tags, we removes white spaces from it
			tag = gensub(/\s*/, "", "g", tags[i]);

			# converting the tags
			out_tag = translate[tag];

			# this is the comment we need
			comment = comments[i+1];

			#print "/// -> tag: " tag "; out_tag: " out_tag "; comment: " comment
			switch (out_tag)
			{
				case "skip":
				break;
				case "param":
					par = gensub(/^([^ ]{1,})[ ](.*)$/,"\\1","",comment);
					comm = gensub(/^([^ ]{1,})[ ](.*)$/,"\\2","",comment);
					comm = gensub(/String\^/, "string","g", comm);
					print LINE_START "/// <" out_tag " name=\"" par "\">" comm "</" out_tag ">"
				break;
				default:
					comment = gensub(/String\^/, "string","g", comment);
					print LINE_START "/// <" out_tag ">" comment "</" out_tag ">"
			}

		}
		reset();
		
	}
}


{
	IS_COMMENT=0;
}

# starting of the comment block
/^\s*\/\*\*/ {
	LINE_START = gensub(/\/\*+.*$/,"","",$0);
	IS_COMMENT=1;
	COMMENT_BLOCK=1;
	getcomment($0);
}

# tail of the comment block
/\*\// {
	if (COMMENT_BLOCK == 1)
	{
		getcomment($0);
		IS_COMMENT=1;
		COMMENT_BLOCK=0;
	}
}

# we process the lines 
{
	if (IS_COMMENT == 0)
	{
		if (COMMENT_BLOCK == 0)
		{
			# the comment comes first
			putcomment();
			print;
		}
		else
		{
			# we are inside of a comment block 
			getcomment($0);
		}
	}
}
