#Plant Water Scheduler

Welcome to the plant water scheduler, I created this project for Launch School's RB 175 course.

The Plant Water Scheduler is a Sinatra web application hosted on [Heroku](https://plant-water-scheduler.herokuapp.com/home). You can find the git repository [here](https://github.com/DanielSLew/plant_scheduler).

The idea for a plant water scheduler came from the fact that plants are always getting neglected in my home and not getting the water they need.

This project will help to keep track of all the plants in your home, using unique info for each plant including the type of plant, a photo, how many times a week does it need watering, how many times you've watered it in the current week, and any additional notes you wish to add.

The plants that still need water, will be presented at the top of the page and displayed in green, to indicate that they still need to be watered this week. Whereas plants that have reached its water limit for the week will be displayed in red and moved to the bottom of the plant display.

It will help you take care of your plants, as well as being able to view other user's plant collections.

**Caveat**

Because of Heroku's ephemeral filesystem, the information from this app will be reset every time the dyno is stopped or restarted. So this project is more used as a presentation of concepts I've practiced, as well as a way to cement new concepts.