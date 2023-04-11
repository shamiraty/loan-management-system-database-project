create table Employee
(
    FirstName varchar(100)not null,
    LastName  varchar(100)not null,
    Fullname varchar(100) GENERATED ALWAYS AS (CONCAT(FirstName,' ',LastName)),
    Resident enum('West Dodoma','Noth Kilimanjaro','Arusha','Coast Region','Darusalam'),
    Username varchar(100)not null primary Key
    
)

create table Customers
(
    FirstName varchar(100)not null,
    LastName  varchar(100)not null,
    Fullname varchar(100) GENERATED ALWAYS AS (CONCAT(FirstName,' ',LastName)),
    Resident enum('West Dodoma','Noth Kilimanjaro','Arusha','Coast Region','Darusalam'),
    NationalID varchar(100)not null primary key,
    RequestedLoan double,
    LoanTax double default 10,
    DirectCost double default 10,
    TotalLoanCost double AS (RequestedLoan*(LoanTax+DirectCost)/100)PERSISTENT,
    TakenAmount double AS (RequestedLoan-(RequestedLoan*(LoanTax+DirectCost)/100))PERSISTENT,
    ActualDebt double AS (RequestedLoan+(RequestedLoan*(LoanTax+DirectCost)/100))PERSISTENT,
    index customerIndex(NationalID,Fullname),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    RemainAmount double default 0,
    Status varchar(100) DEFAULT 'Installments on Progress',
    password varchar(250)not null,
    AddedBy varchar(100),
    foreign key(AddedBy)references Employee(Username) on update cascade on delete cascade

)


create table Installments
(
  id int(11)primary key auto_increment,
  InstalledAmount double,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  National_ID varchar(100),
  EmployeeUsername varchar(100),
  foreign key(National_ID)references Customers(NationalID) on update cascade on delete cascade,
  foreign key(EmployeeUsername)references Employee(Username) on update cascade on delete cascade
)

create table message
(
NationalID varchar(100),
Heading varchar(100),
Status varchar(100) default 'Disapproved',
message varchar(100),
foreign key(NationalID)references Customers(NationalID) on update cascade on delete cascade
)
DELIMITER $$
create trigger compute
 after insert on Installments
 for each row 
 begin
 set @ActualDebt=
(
  select ActualDebt
  from Customers where
  NationalID=new.National_ID
);
set @totalInstallment=
(
select sum(InstalledAmount)
from Installments where 
National_ID=new.National_ID
);
if @ActualDebt=@totalInstallment or @totalInstallment>=@ActualDebt
then
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'complited';
end if;
update Customers set RemainAmount=@ActualDebt-@totalInstallment 
where Customers.NationalID=new.National_ID;
 if @totalInstallment=@ActualDebt 
 then
 update Customers set Status='Complited'
 where NationalID=new.National_ID;
 end if;
 end $$

