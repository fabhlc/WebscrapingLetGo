
# Scraping listings from a dynamic Javascript website using Selenium

### Preamble
Bicycle theft has been very prevalent these past few weeks as the weather in Toronto has been getting warmer. A friend was devastated hers was stolen, but she saw it posted on LetGo.com not long after. While she never had it recovered, what if we could scrape a listings website daily to see which user or location frequently sells bikes? 

I attempted with Beautiful Soup - the standard webscraping package - but soon realized Javascript Links work differently. And although I soon realized this was a far-fetched idea (e.g. poster could create new accounts each time), the challenge of learning Selenium enticed me to carry this through.

### Introduction

This is a code that scrapes information from listings for bicycles in Toronto off a dynamic webpage built on Javascript, LetGo.com. 

First, we import the modules needed and assign the web address to a variable. Note that the search query has already been entered. 


```python
from bs4 import BeautifulSoup as soup
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver import ActionChains
from random import randint
from datetime import datetime
import os
import time
import csv

url = "https://ca.letgo.com/en/search/bike%20bicycles"
```

Next we initiate the webdriver (having downloaded chromedriver already) from its location in our system. Note that putting the code to sleep will give time not only for us to see what is happening, but for Chrome to actually load what we told it to.


```python
driver = webdriver.Chrome(r'C:/Users/Fabienne/Py_Practice/chromedriver.exe')
driver.get(url)
time.sleep(2) #pauses for 2 seconds
```

We need to zone in on the location for our search. We identify location_box by xpath, then click on it for a pop-up, in which we type "Toronto, ON, Canada", select from the dropdown list via arrow keys, wait a sec for it to properly load, then press submit.


```python
location_box = driver.find_element_by_xpath('//div[@class="sc-jnlKLf fJBPoC"]')
location_box.click()
time.sleep(2)
location_popup = driver.find_element_by_xpath('//div[@class = "sc-gisBJw knqFpP"]//input[@type="search"]')
location_popup.clear()
location_popup.send_keys('Toronto, ON, Canada')
time.sleep(1)
location_popup.send_keys(Keys.DOWN, Keys.RETURN)
time.sleep(2)

location_submit = driver.find_element_by_xpath('//button[@class="sc-iwsKbI bLghaB sc-ifAKCX zcOkP"]')
location_submit.click()
time.sleep(2)
```

We want to search within a 10km radius and must use the sliding scale to do so. This requires an "action" which we will store as 'move'. Through trial and error, we identify that the argument 'xoffset' needs to be at '50' to move it to '10km'. 


```python
move = ActionChains(driver)
location_slider = driver.find_element_by_xpath('//div[@class = "input-range__track input-range__track--background"]//div[@class = "input-range__slider"]')
move.click_and_hold(location_slider).move_by_offset(xoffset=50, yoffset=0).release().perform()
time.sleep(3)
```

Let's scroll down a few times to load more items. This will allow this script to capture a larger number of listings.


```python
driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
time.sleep(2)
# driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
# time.sleep(2)
# driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
# time.sleep(2)
```

Containers! My favourite. Each 'container' identifies each listing. Since we'll need to go into each listing's page to get any useful information, we'll need to grab their links. Let's store them in a list for easy accessing. 


```python
containers = driver.find_elements_by_xpath('//div[@class="ReactVirtualized__Collection__cell"]//a')
link_list = []
for container in containers:
    html = container.get_attribute("href")
    link_list.append(html)
```

We'll create a unique filename for each csv file, using datetime. 


```python
x = datetime.today()
filename = 'LetGo_bikes_'+ x.strftime('%Y-%m-%d_%H%M') +'.csv'
```

We want eight data points from each listing:
- item name
- price
- description
- location
- post date
- user
- user link (for easy access later)
- item_url (for reference)

We'll identify them by xpath, store them in a list, then write each list as a line in our csv file.


```python
with open(filename,'w', newline='', encoding='utf-8') as file:
    
    #Create header
    file.write('item_name,price, description,location,post_date,user,user_link,item_url,\n')
    
    for item_url in link_list:
        driver.get(item_url)
        attribute_list = []

        item_name = driver.find_element_by_xpath('//div[@class = "flex flex-column justify-between product-page__main-container___23Czq"]//h1').text
        price = driver.find_element_by_xpath('//div[@class="Box product-page__user-price___36nF3"]//h3').text
        description = driver.find_element_by_xpath('//span[@class="ProductDetail__name-description___1-PCj"]').text.strip().replace('\n','; ')
        location = driver.find_element_by_xpath('//div[@class="overflow-hidden"]//h4').text
        post_date = driver.find_element_by_xpath('//div[@class="Flex ProductDetail__badges___g0ZvT"]//div//div').text
        user = driver.find_element_by_xpath('//span[@class="product-page__userName___TxLGJ"]').text
        user_link = driver.find_element_by_xpath('//div[@class="Box"]//div//div//a').get_attribute("href")

        attribute_list = [[item_name]+[price]+ [description]+ [location]+ [post_date]+ [user]+ [user_link]+ [item_url]]
        
        writer = csv.writer(file, delimiter = ",")
        writer.writerows(attribute_list)
        
        time.sleep(randint(2,10))
driver.quit()
```

Let's take a look at our output.


```python
with open(filename, encoding='utf-8') as file:
    for i in file.readlines()[:6]:
        print(i)
```

    item_name,price, description,location,post_date,user,user_link,item_url,
    
    Bike Rack,CA$50,"one bike rack available, can be attached at a wall.","Toronto, M8Y 3H8",19 days ago,EDF,https://ca.letgo.com/en/u/edf_184591c1-6816-49bc-a547-7b61b55e7f0e,https://ca.letgo.com/en/i/bike-rack_f62d4dab-6f6a-4472-95e2-559ddfc6126c
    
    Bicycle,CA$499,Louis Garneau 2018 city bicycles . No tax for the entire month of March ! Check us out at 127 Ossington . Bike Repair shop,"Toronto, M6J 2Z6",1+ month,Alessandro Bertucc,https://ca.letgo.com/en/u/alessandro-bertucc_23f5fa4e-b41b-4f91-97b6-8a95c9fcd385,https://ca.letgo.com/en/i/bicycle_c1b36927-638a-48ea-80b1-5264ba7c919c
    
    Bros Blue mountain bike,CA$180,Medium-sized mountain bike with blue frame; Tires are still good.; Belong to my brother used for one season.; Come try it out; Pick up only,"Toronto, M6N 1C6",1+ month,Krissy Calkins,https://ca.letgo.com/en/u/krissy-calkins_3ec1e6aa-c689-415e-b0ed-2b139ea08b03,https://ca.letgo.com/en/i/bros-blue-mountain-bike_4fd15784-1082-4092-8a93-beca21686626
    
    gray narco BMX bike firm price do not msg if not buying,CA$90,I have a bmx for sale i put alot of work and money into it about $200 so i think $100 should be fine andd it is also meant for kids but it can hold an adult which it might be hard to ride it,"Toronto, M5T 2J5",1+ month,Jordan Man,https://ca.letgo.com/en/u/jordan-man_41213c26-3336-4d94-bb08-6c50e1124dd0,https://ca.letgo.com/en/i/gray-narco-bmx-bike-firm-price-do-not-msg-if-not-buying_44f447fe-5128-45a9-964c-e15708aca40c
    
    Huffy Mountain Bike,CA$80,"Bike is like new and recently tuned up!; It has 26"" tires and would be considered a women's small.","Toronto, M6S 3R2",1+ month,Orange Bus,https://ca.letgo.com/en/u/orange-bus_cae6bf1a-1db4-4490-9f10-7c3dac8f7aba,https://ca.letgo.com/en/i/huffy-mountain-bike_8e7daad3-e6a2-4872-93d7-f66a25b445ce
    
    

And there we have it. Now we just need to set this to run automatically (via Windows Task Scheduler) perhaps for a month, daily, and hope the randomized sleep times are enough to keep us from getting banned.
