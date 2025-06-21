codeunit 5445557 "LKN Common Constants"
{
    Access = Public;

    procedure GetCompanyName(): Text
    begin
        exit('LKN Test Company');
    end;

    procedure GetDefaultDateFormat(): Text
    begin
        exit('<Year4>-<Month,2>-<Day,2>');
    end;

    procedure GetMaxTextLength(): Integer
    begin
        exit(250);
    end;

    procedure GetVersionInfo(): Text
    begin
        exit('LKN Common Library v1.0.0');
    end;
}