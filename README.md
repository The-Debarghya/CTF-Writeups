# Pedometer-In-Real-World
A simple application that counts number of steps covered by a person.

* Accepts smartphone inbuilt **Accelerometer** data through a web interface and then calculates number of steps, time elapsed and approximate distance covered.
* The Web Interface uses a simple Ruby framework `sinatra` and no other dependencies are involved.
`docker run -it --rm -p 4567:4567 -v log:/app/log -v uploads:/app/public/uploads pedometer`

* *Currently not a standalone Mobile Application*

*P.S.-Currently under development of proper interface, but the data analysis part remains same!*
