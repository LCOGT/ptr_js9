import sys, datetime

text_to_return = (
    f"This text was created in a server-side python script on "
    f"{datetime.datetime.now()}." 
)

print(text_to_return)
sys.exit(0)
