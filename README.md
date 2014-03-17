Velocity Code
=============

### Code sample consists of two simple 'applications' ###

<ol>
<li>Orders - A sample of controllers, modelrs, spec etc.</li>
<li>OOP - A sample of usage of Object Oriented Programming in Ruby on Rails</li>
</ol>

## Orders ##

The small 'application' is consisted of:

> 1.   Controller
> 2.   Model
> 3.   Contoller spec
> 2.   Model spec
> 2.   Request spec

### 1. Controller ###

Controller represents the 'simple' REST. Contoller represents controller organization, keeping the controller as thin as possible. It represents usage of before filters and types of responds (API controllers will be added in next chapters)

### 2. Model ###

Model shows usage of polimorfic association, before validations and simple aliases 

### 3. Contoller spec ###

Spec for controller represents usage of <code>let</code> and <code>let!</code>.
It shows usage of shared examples, and using helpers inside specs.

### 4. Model spec ###

Model specs again uses <code>let</code> and <code>let!</code> helper methods, but also represents how to use <code>it "should" </code> in tests.


### 5. Request spec ###

Spec for Admin center.


## OOP ##

The code sample is consisted of more advanced approach to building the applications. Although these are just small fractions of codes, it represents usage of classes and inheritance and testing of such model:

### Model and spec ###

The code is located in oop directory. The code has elements that will have to include other elements so it could be explained better, but this is just an example of a simple Class and the spec for it.
