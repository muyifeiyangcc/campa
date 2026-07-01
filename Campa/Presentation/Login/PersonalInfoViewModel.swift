import Foundation

enum PersonalInfoGender: String {
    case male
    case female
}

final class PersonalInfoViewModel {
    let nameTitle = NSLocalizedString("Name:", comment: "Personal info name label")
    let birthdayTitle = NSLocalizedString("Birthday:", comment: "Personal info birthday label")
    let locationTitle = NSLocalizedString("University:", comment: "Personal info university label")
    let genderTitle = NSLocalizedString("Gender:", comment: "Personal info gender label")
    let namePlaceholder = NSLocalizedString("Enter username", comment: "Personal info name placeholder")
    let birthdayPlaceholder = NSLocalizedString("2003-01-01", comment: "Personal info birthday placeholder")
    let locationPlaceholder = NSLocalizedString("Select university", comment: "Personal info university placeholder")
    let maleTitle = NSLocalizedString("Male", comment: "Male gender option")
    let femaleTitle = NSLocalizedString("Female", comment: "Female gender option")
    let saveTitle = NSLocalizedString("Save", comment: "Save personal info")
    let defaultGender: PersonalInfoGender = .male
    let requiredInfoMessage = NSLocalizedString("Please complete all information", comment: "Personal info required fields toast")
    let requiredAvatarMessage = NSLocalizedString("Please upload your avatar", comment: "Personal info avatar required toast")
    let missingRegistrationMessage = NSLocalizedString("Missing sign up information", comment: "Missing registration draft toast")
    let saveFailedMessage = NSLocalizedString("Save failed", comment: "Personal info save failure toast")

    let universityNames: [String]

    init() {
        universityNames = Self.worldUniversityNames
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private static let worldUniversityNames = [
        "Aalto University",
        "Aarhus University",
        "Arizona State University",
        "Australian National University",
        "Boston University",
        "Brown University",
        "California Institute of Technology",
        "Carnegie Mellon University",
        "Chung-Ang University",
        "City University of Hong Kong",
        "Columbia University",
        "Cornell University",
        "Delft University of Technology",
        "Dongguk University",
        "Duke University",
        "ETH Zurich",
        "Erasmus University Rotterdam",
        "Fudan University",
        "George Washington University",
        "Georgia Institute of Technology",
        "Harvard University",
        "Heidelberg University",
        "Hong Kong University of Science and Technology",
        "Hongik University",
        "Humboldt University of Berlin",
        "Hanyang University",
        "Imperial College London",
        "Indiana University Bloomington",
        "Johns Hopkins University",
        "KAIST",
        "King's College London",
        "Korea University",
        "Kyoto University",
        "Leiden University",
        "London School of Economics and Political Science",
        "Ludwig Maximilian University of Munich",
        "Lund University",
        "Massachusetts Institute of Technology",
        "McGill University",
        "Michigan State University",
        "Monash University",
        "Nanyang Technological University",
        "National Taiwan University",
        "National University of Singapore",
        "New York University",
        "Northwestern University",
        "Ohio State University",
        "Osaka University",
        "Peking University",
        "Pennsylvania State University",
        "Pohang University of Science and Technology",
        "Princeton University",
        "Purdue University",
        "Rice University",
        "Sapienza University of Rome",
        "Sciences Po",
        "Seoul National University",
        "Shanghai Jiao Tong University",
        "Sogang University",
        "Sorbonne University",
        "Stanford University",
        "Sungkyunkwan University",
        "Technical University of Munich",
        "Texas A&M University",
        "The Chinese University of Hong Kong",
        "The University of Edinburgh",
        "The University of Hong Kong",
        "The University of Manchester",
        "The University of Melbourne",
        "The University of Queensland",
        "The University of Sydney",
        "Tohoku University",
        "Tokyo Institute of Technology",
        "Tsinghua University",
        "UCL",
        "UNSW Sydney",
        "University College Dublin",
        "University of Amsterdam",
        "University of Auckland",
        "University of Barcelona",
        "University of British Columbia",
        "University of California, Berkeley",
        "University of California, Los Angeles",
        "University of Cambridge",
        "University of Chicago",
        "University of Copenhagen",
        "University of Helsinki",
        "University of Illinois Urbana-Champaign",
        "University of Michigan",
        "University of New South Wales",
        "University of Oxford",
        "University of Pennsylvania",
        "University of Sao Paulo",
        "University of Seoul",
        "University of Southern California",
        "University of Toronto",
        "University of Tokyo",
        "University of Vienna",
        "University of Washington",
        "University of Wisconsin-Madison",
        "Uppsala University",
        "Utrecht University",
        "Virginia Tech",
        "Yale University",
        "Yonsei University",
        "Zhejiang University"
    ]
}
