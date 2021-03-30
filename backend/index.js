// import required packages
var express = require('express')
var multer  = require('multer')
var fs = require('fs');

// set multer destination
var upload = multer({ dest: 'uploads/'  })

// start app with express
var app = express()

// if the app receives a post request, download file received into /uploads
app.post('/upload', upload.single("picture"), function (req,res) {
  console.log("Received file" + req.file.originalname); // debug info

  // create read and write streams
  var src = fs.createReadStream(req.file.path);
  var dest = fs.createWriteStream('uploads/' + req.file.originalname);
  src.pipe(dest);
  src.on('end', function() {
    fs.unlinkSync(req.file.path);
    // send OK response back to client
    res.json('OK: received ' + req.file.originalname);
    console.log("file: " + req.file.originalname); // debug info
  });

  // send an error response if there is an error
  src.on('error', function(err) { res.json('Something went wrong!');  });
})

// set /uploads as a static folder for getting images back
app.use('/uploads', express.static('uploads'))

// set listener on port 5337
let port = process.env.PORT || 5337;
app.listen(port, function () {
  return console.log("Started file upload server on port " + port);
});
