walker interact {
    can return_message with `root entry {
        report {
            "response": "Hello, world!"
        };
    }
}

walker interact_with_body {
    has name: str;

    can return_message with `root entry {
        report {
            "response": "Hello, " + self.name + "!"
        };
    }
}

walker additional_walker_one {
    has name: str;
    has school: str;

    can return_message with `root entry {
        report {
            "response": "Hello " + self.name + " from " + self.school + "!"
        };
    }
}

walker additional_walker_two {
    has name: str;
    has age: int;

    can return_message with `root entry {
        report {
            "response": "Hello " + self.name + " who is " + str(self.age) + " years old!"
        };
    }
}