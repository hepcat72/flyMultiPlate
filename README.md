# flyMultiPlate

A matlab suite of scripts and functions to track & record fruit fly movement in order to describe a movement phenotype.

## Installation

Ready to use - just download.

## Requirements

* Matlab 2016b+
* A PointGray camera is required (unless you are processing a previously saved video file).
* flyCapture 2.5+

## Usage

Main script: flyMultiPlateScript.m

1. Connect 1 or more PointGrey cameras to your computer via USB (pointing at 1-6 96 well plates in an opaque box and a light sources underneath the plate(s))
2. Start matlab
3. Change directories in matlab to the flyMultiPlate directory
4. Open flyMultiPlateScript.m, adjust the parameters at the top of the script to your liking, and save.
5. Run flyMultiPlateScript.m
6. Click OK to clear memory
7. If You have multiple cameras connected, enter the number of cameras you want to use and click OK
8. If You have multiple cameras connected, select a camera to configure and click OK
9. Adjust the camera settings for best image and then close the preview window
10. Enter the number of plates for this camera and click OK
11. Click the center of well A1 of a new plate
12. Click the center of well H1 of the same plate clicked in the previous step
13. Adjust the well markings using the sliders and close the window
14. If there are still plates without well markings, return to step 11.
15. If there are more cameras, you'll automatically be returned to step 8.

## Limitations

Determining presumed time of death of each fly is accomplished by a companion perl script called flyReaper.pl, whose release is pending.  Current time of death output files are not populated.

## Known Issues

A random/rare matlab crash is known to occur due to an 'Access violation'.  This is believed to have been fixed, but it's difficult to confirm, so please report if you encounter this issue on the github page for this repository.

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request

## History

This script was originally obtained, with permission from Harvard University, enhanced by Ben Bratton, adjusted but Sudarshan Chari to tweak the user workflow and obtain desired outputs, and updated for memory usage, UI features, reliability, and multiple camera support by Robert Leach.

## Credits

* Harvard University
* Ben Bratton
* Sudarshan Chari
* Robert Leach

Lewis Sigler Institute for Integrative Genomics,
Princton University

## License

See LICENSE (3-Clause BSD License)
