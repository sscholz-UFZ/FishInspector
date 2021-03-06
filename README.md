# FishInspector
**Annotation of features from zebrafish embryos**

The software FishInspector allows annotation of features in images of zebrafish embryos. The recent version requires images of a lateral position. It is important that the position is precise since deviation may confound with feature annotations. Images from any source can be used. However, depending on the image properties parameters may have to be adjusted. Furthermore, images obtained with normal microscope and not using an automated position system with embryos in glass capillaries require conversion using a KNIME workflow (available [here](https://github.com/eteixido/Knime-workflows-FishInspector)). As a result of the analysis the software provides JSON files that contain the coordinates of the features. Coordinates are provided for eye, fish contour, notochord , otoliths, yolk sac, pericard and swimbladder. Furthermore, pigment cells in the notochord area are detected. Additional features can be manually annotated. It is the aim of the software to provide the coordinates, which may then be analysed subsequently to identify and quantify changes in the morphology of zebrafish embryos.

## [Available for Download Here](https://github.com//sscholz-UFZ/FishInspector/releases)

## User Guide

The complete user guide can be checked [here](https://github.com/sscholz-UFZ/FishInspector/blob/master/docs/Index.md)

## Referencing

Citations can be made using the following DOI:

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1422642.svg)](https://doi.org/10.5281/zenodo.1422642)

*Teixido, E., Kießling, T.R., Krupp, E., Quevedo, C., Muriana, A., Scholz, S., 2018. Automated morphological feature assessment for zebrafish embryo developmental toxicity screens. Tox. Sci. accepted.*

## License

This project is licensed under a GNU General Public License - see the [LICENSE](LICENSE) file for details and also this [file](License.txt). 



