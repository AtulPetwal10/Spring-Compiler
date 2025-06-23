
show->"hey this is spring language";   //priting string

a<-2;   //assigning integer value to variable
show->"value of a is:";
show->a;  //output of variable

show->123;




pie<-3.14;   //assigning floating point value to variable
show->"value of pie is:";
show->pie;   //output the value of variable


a<-2+1;   //arithmetic - also supports precedence and associativity
b<-2;
show->a;
show->a+1; 
show->b+a;
b<-(1+1)*10-5;  //aritmetic expression ==15
show->b;


negative<-10-5; //handling negative numbers
show->negative;

negative<--10+5;
show->negative;


mod<-10%3;  //modular
show->mod;


//support of logical and relational operators
x <- 10;
y <- 20;
show -> x < y;     
show -> (x < y) && (x != y);
show -> !(x == y);



//taking number and string as a input
x<-take;
show->x;



//conditional

age<-take;
if (age>18) {
    show -> "age is greater than 18";
} else {
    show -> "age is not greater than 18";
}













